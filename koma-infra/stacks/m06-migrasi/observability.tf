# Modul 06 — log, alarm, dan dasbor sebagai kode. Ikuti naskah Bagian D.

resource "aws_cloudwatch_log_group" "api" {
  name              = local.log_group
  retention_in_days = 1

  tags = {
    Name  = "${local.awalan}-log"
    peran = "observability"
  }
}

resource "aws_cloudwatch_metric_alarm" "latensi" {
  alarm_name          = "${local.awalan}-latensi-p95"
  alarm_description   = "Latensi p95 ALB melebihi ${var.ambang_latensi_detik} detik"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "TargetResponseTime"
  extended_statistic  = "p95"
  period              = 60
  evaluation_periods  = 1
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.ambang_latensi_detik
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = aws_lb.api.arn_suffix
  }

  tags = {
    Name  = "${local.awalan}-latensi-p95"
    peran = "observability"
  }
}

resource "aws_cloudwatch_dashboard" "api" {
  dashboard_name = local.awalan

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title   = "Permintaan ALB per Menit"
          region  = var.region
          stat    = "Sum"
          period  = 60
          metrics = [["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.api.arn_suffix]]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title   = "Latensi p95 TargetResponseTime (dtk)"
          region  = var.region
          stat    = "p95"
          period  = 60
          metrics = [["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", aws_lb.api.arn_suffix]]
          annotations = {
            horizontal = [{
              label = "Ambang p95"
              value = var.ambang_latensi_detik
            }]
          }
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title   = "Target Sehat (Hijau)"
          region  = var.region
          stat    = "Minimum"
          period  = 60
          metrics = [["AWS/ApplicationELB", "HealthyHostCount", "TargetGroup", aws_lb_target_group.hijau.arn_suffix, "LoadBalancer", aws_lb.api.arn_suffix]]
        }
      },
      {
        type   = "alarm"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "Status Alarm Latensi p95"
          alarms = [aws_cloudwatch_metric_alarm.latensi.arn]
        }
      }
    ]
  })
}
