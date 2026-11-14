# Modul 00 — Stack Verifier: Role ReadOnly untuk Verifier Otomatis

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }
}

resource "aws_iam_role" "verifier" {
  name               = "koma-verifier-ro"
  description        = "Role read-only untuk verifier otomatis praktikum Komputasi Awan"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = {
    Name       = "koma-verifier-ro"
    nim        = var.nim
    kelompok   = var.kelompok
    modul      = "m00"
    stack      = "m00-verifier"
    managed-by = "opentofu"
  }
}

resource "aws_iam_role_policy_attachment" "readonly" {
  role       = aws_iam_role.verifier.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}
