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
# TODO C.5  antrean -antrean di prod wajib disertai antrean -gagal prod di plan yang sama.
#           (redrive_policy tidak dapat dipakai: lihat naskah, after_unknown.)

# ---------------------------------------------------------------- aturan 4
# TODO C.5  fungsi Lambda prod tidak boleh < 256 MB; fungsi mana pun maks. 512 MB dan timeout maks. 30 detik.

# ---------------------------------------------------------------- aturan 5
# TODO C.5  kebijakan IAM inline (aws_iam_role_policy, aws_iam_policy) tanpa aksi "*" atau "layanan:*"
#           (salin pembantu aksi() dan wildcard() dari m05.rego, ganti paketnya).
