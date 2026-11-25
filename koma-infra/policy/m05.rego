# Kebijakan Modul 05: menolak plan yang membuka enam temuan stack rawan.
# Starter: aturan 1 dan 3 sudah jadi; lengkapi aturan 2, 4, 5, dan 6 (Bagian B).
# Dijalankan atas plan JSON:  conftest test rawan.plan.json --policy ../../policy
package main

import rego.v1

# Nama yang dianggap menyimpan rahasia (variabel, output).
pola_rahasia := `(?i)(password|passwd|secret|token|api_key|kunci_api)`

# Nilai rahasia tertulis langsung: NAMA=nilai, bukan NAMA=$VARIABEL.
pola_nilai_rahasia := `(?i)(password|passwd|secret|token)\s*[=:]\s*["']?[^\s"'$]`

port_admin := {22, 3389}

# ---------------------------------------------------------------- aturan 1 (starter)
# Bucket policy yang mengizinkan siapa pun (Principal "*").

publik("*")

publik(p) if p.AWS == "*"

publik(p) if "*" in p.AWS

deny contains msg if {
	rc := input.resource_changes[_]
	rc.type == "aws_s3_bucket_policy"
	s := json.unmarshal(rc.change.after.policy).Statement[_]
	s.Effect == "Allow"
	publik(s.Principal)
	msg := sprintf("%s: bucket policy mengizinkan akses publik (Principal *)", [rc.address])
}

# ---------------------------------------------------------------- aturan 2
# Tolak aws_vpc_security_group_ingress_rule yang sumbernya 0.0.0.0/0 atau ::/0
# DAN mencakup port admin (22 atau 3389, termasuk rentang) atau ip_protocol "-1".

sumber_dunia(a) if a.cidr_ipv4 == "0.0.0.0/0"

sumber_dunia(a) if a.cidr_ipv6 == "::/0"

mencakup_admin(a) if a.ip_protocol == "-1"

mencakup_admin(a) if {
	some p in port_admin
	is_number(a.from_port)
	is_number(a.to_port)
	a.from_port <= p
	p <= a.to_port
}

deny contains msg if {
	rc := input.resource_changes[_]
	rc.type == "aws_vpc_security_group_ingress_rule"
	a := rc.change.after
	sumber_dunia(a)
	mencakup_admin(a)
	msg := sprintf("%s: aturan ingress membuka akses publik ke port admin atau semua protokol", [rc.address])
}

# ---------------------------------------------------------------- aturan 3 (starter)
# Variabel bernama rahasia yang punya nilai bawaan: rahasianya tertulis di kode.

deny contains msg if {
	some nama, v in input.configuration.root_module.variables
	regex.match(pola_rahasia, nama)
	"default" in object.keys(v)
	msg := sprintf("var.%s: variabel rahasia punya nilai bawaan", [nama])
}

# ---------------------------------------------------------------- aturan 4
# Tolak output yang namanya cocok pola_rahasia dan tidak ditandai sensitive.

deny contains msg if {
	some nama, o in input.configuration.root_module.outputs
	regex.match(pola_rahasia, nama)
	not o.sensitive
	msg := sprintf("output.%s: output rahasia tidak ditandai sensitive = true", [nama])
}

# ---------------------------------------------------------------- aturan 5
# Tolak aws_instance yang change.after.user_data cocok pola_nilai_rahasia.

deny contains msg if {
	rc := input.resource_changes[_]
	rc.type == "aws_instance"
	ud := rc.change.after.user_data
	is_string(ud)
	regex.match(pola_nilai_rahasia, ud)
	msg := sprintf("%s: user_data memuat nilai rahasia langsung", [rc.address])
}

# ---------------------------------------------------------------- aturan 6
# Tolak aws_iam_role_policy atau aws_iam_policy dengan pernyataan Allow aksi "*" atau "<layanan>:*".

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
	rc := input.resource_changes[_]
	rc.type in {"aws_iam_role_policy", "aws_iam_policy"}
	pol := rc.change.after.policy
	is_string(pol)
	s := pernyataan_iam(json.unmarshal(pol))[_]
	s.Effect == "Allow"
	aksi_liar(s.Action)
	msg := sprintf("%s: kebijakan IAM mengizinkan aksi wildcard (* atau <layanan>:*)", [rc.address])
}
