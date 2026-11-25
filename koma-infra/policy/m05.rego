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
# TODO aturan 2: tolak aws_vpc_security_group_ingress_rule yang sumbernya 0.0.0.0/0 (cidr_ipv4)
# atau ::/0 (cidr_ipv6) DAN mencakup port admin (22 atau 3389, termasuk rentang from_port..to_port
# yang melewatinya) atau ip_protocol "-1" (semua protokol). Pesan menyebut rc.address.

# ---------------------------------------------------------------- aturan 3 (starter)
# Variabel bernama rahasia yang punya nilai bawaan: rahasianya tertulis di kode.

deny contains msg if {
	some nama, v in input.configuration.root_module.variables
	regex.match(pola_rahasia, nama)
	"default" in object.keys(v)
	msg := sprintf("var.%s: variabel rahasia punya nilai bawaan", [nama])
}

# ---------------------------------------------------------------- aturan 4
# TODO aturan 4: tolak output yang namanya cocok pola_rahasia dan tidak ditandai sensitive
# (input.configuration.root_module.outputs).

# ---------------------------------------------------------------- aturan 5
# TODO aturan 5: tolak aws_instance yang change.after.user_data cocok pola_nilai_rahasia.

# ---------------------------------------------------------------- aturan 6
# TODO aturan 6: tolak aws_iam_role_policy atau aws_iam_policy yang kebijakannya punya pernyataan
# Allow dengan aksi "*" atau "<layanan>:*". Action boleh string atau daftar (lihat aturan 1 untuk
# cara membaca JSON kebijakan).
