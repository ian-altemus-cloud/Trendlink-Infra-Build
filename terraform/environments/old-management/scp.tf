resource "aws_organizations_policy" "region_lockdown" {
  name        = "tl-region-lockdown"
  description = "Deny resource creation outside us-east-1 and deny disabling CloudTrail"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyOutsideUsEast1"
        Effect = "Deny"
        NotAction = [
          "iam:*",
          "organizations:*",
          "support:*",
          "sts:*"
        ]
        Resource = "*"
        Condition = {
          StringNotEquals = {
            "aws:RequestedRegion" = "us-east-1"
          }
        }
      },
      {
        Sid    = "DenyDisableCloudTrail"
        Effect = "Deny"
        Action = [
          "cloudtrail:DeleteTrail",
          "cloudtrail:StopLogging",
          "cloudtrail:UpdateTrail"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_organizations_policy_attachment" "region_lockdown_root" {
  policy_id = aws_organizations_policy.region_lockdown.id
  target_id = aws_organizations_organization.tl_org.roots[0].id
}