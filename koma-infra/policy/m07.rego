# Kebijakan Modul 07: gerbang tata kelola atas plan stack m07-integrasi (G4, H6).
# Dijalankan pipeline sebelum apply, dan secara lokal:
#   tofu show -json dev.tfplan > dev.plan.json
#   conftest test dev.plan.json --policy ../../policy --namespace m07
# Paket m07 terpisah dari paket main (m05.rego) agar kebijakan Modul 05 tidak ikut menilai
# plan Modul 07 dan sebaliknya.
package m07

import rego.v1

label_wajib := {"owner", "lingkungan", "cost-center", "data-class"}

kelas_data := {"publik", "internal", "rahasia"}

lingkungan_sah := {"dev", "prod"}

# Resource yang ada sesudah plan (bukan yang dihapus).
diubah contains rc if {
	some rc in input.resource_changes
	rc.change.after != null
}

bertag contains rc if {
	some rc in diubah
	is_object(rc.change.after.tags_all)
}

tag(rc, k) := rc.change.after.tags_all[k]

# ---------------------------------------------------------------- aturan 1 (starter)
# Setiap resource bertag membawa label G4 yang lengkap dan sah.

deny contains msg if {
	some rc in bertag
	some k in label_wajib
	not rc.change.after.tags_all[k]
	msg := sprintf("%s: label %s tidak ada", [rc.address, k])
}

deny contains msg if {
	some rc in bertag
	not regex.match(`^CC-[0-9]{3}$`, tag(rc, "cost-center"))
	msg := sprintf("%s: cost-center %q tidak berbentuk CC-123", [rc.address, tag(rc, "cost-center")])
}

deny contains msg if {
	some rc in bertag
	not tag(rc, "data-class") in kelas_data
	msg := sprintf("%s: data-class %q tidak dikenal", [rc.address, tag(rc, "data-class")])
}

deny contains msg if {
	some rc in bertag
	not tag(rc, "lingkungan") in lingkungan_sah
	msg := sprintf("%s: lingkungan %q tidak dikenal", [rc.address, tag(rc, "lingkungan")])
}

deny contains msg if {
	some rc in bertag
	tag(rc, "owner") != tag(rc, "nim")
	msg := sprintf("%s: owner %q bukan NIM pemilik %q", [rc.address, tag(rc, "owner"), tag(rc, "nim")])
}

# ---------------------------------------------------------------- aturan 2 (starter)
# Data rahasia hanya boleh berada di prod.

deny contains msg if {
	some rc in bertag
	tag(rc, "data-class") == "rahasia"
	tag(rc, "lingkungan") != "prod"
	msg := sprintf("%s: data rahasia di lingkungan %s", [rc.address, tag(rc, "lingkungan")])
}

# ---------------------------------------------------------------- aturan 3
# antrean -antrean di prod wajib disertai antrean -gagal prod di plan yang sama.

antrean_gagal_ada(nama_antrean) if {
	some dlq in diubah
	dlq.type == "aws_sqs_queue"
	dlq.change.after.name == concat("", [trim_suffix(nama_antrean, "-antrean"), "-gagal"])
}

deny contains msg if {
	some rc in bertag
	rc.type == "aws_sqs_queue"
	tag(rc, "lingkungan") == "prod"
	endswith(rc.change.after.name, "-antrean")
	not antrean_gagal_ada(rc.change.after.name)
	msg := sprintf("%s: antrean prod (%s) wajib disertai antrean DLQ (-gagal)", [rc.address, rc.change.after.name])
}

# ---------------------------------------------------------------- aturan 4
# fungsi Lambda prod tidak boleh < 256 MB; fungsi mana pun maks. 512 MB dan timeout maks. 30 detik.

deny contains msg if {
	some rc in bertag
	rc.type == "aws_lambda_function"
	tag(rc, "lingkungan") == "prod"
	is_number(rc.change.after.memory_size)
	rc.change.after.memory_size < 256
	msg := sprintf("%s: fungsi Lambda prod minimal 256 MB (terpasang %d MB)", [rc.address, rc.change.after.memory_size])
}

deny contains msg if {
	some rc in diubah
	rc.type == "aws_lambda_function"
	is_number(rc.change.after.memory_size)
	rc.change.after.memory_size > 512
	msg := sprintf("%s: fungsi Lambda melebihi batas 512 MB (terpasang %d MB)", [rc.address, rc.change.after.memory_size])
}

deny contains msg if {
	some rc in diubah
	rc.type == "aws_lambda_function"
	is_number(rc.change.after.timeout)
	rc.change.after.timeout > 30
	msg := sprintf("%s: timeout Lambda melebihi batas 30 detik (terpasang %d detik)", [rc.address, rc.change.after.timeout])
}

# ---------------------------------------------------------------- aturan 5
# kebijakan IAM inline (aws_iam_role_policy, aws_iam_policy) tanpa aksi "*" atau "layanan:*".

pernyataan_iam(doc) := doc.Statement if is_array(doc.Statement)

pernyataan_iam(doc) := [doc.Statement] if is_object(doc.Statement)

aksi_wildcard(s) if s == "*"

aksi_wildcard(s) if endswith(s, ":*")

aksi_liar(a) if {
	is_string(a)
	aksi_wildcard(a)
}

aksi_liar(a) if {
	is_array(a)
	some item in a
	aksi_wildcard(item)
}

deny contains msg if {
	some rc in diubah
	rc.type in {"aws_iam_role_policy", "aws_iam_policy"}
	pol := rc.change.after.policy
	is_string(pol)
	s := pernyataan_iam(json.unmarshal(pol))[_]
	s.Effect == "Allow"
	aksi_liar(s.Action)
	msg := sprintf("%s: kebijakan IAM mengizinkan aksi wildcard (* atau <layanan>:*)", [rc.address])
}
