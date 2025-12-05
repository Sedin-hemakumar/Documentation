# Route53 
```
Terraform AWS Route53 Reverse DNS Module
This repository provides a reusable Terraform module for creating an AWS Route53 Reverse DNS Zone (e.g., 71.53.52.in-addr.arpa) along with all required DNS records:

--> SOA (Start of Authority)
--> NS (Name Server)
--> PTR (Reverse Lookup)

The root module passes input variables into the Route53 sub-module, and the sub-module actually creates all AWS resources.
```
📁 Folder Structure

```route53/
└── 71.53.52.in-addr.arpa/      # Environment / Zone-specific folder
    ├── main.tf                 # Root: Calls module + AWS provider + Local
    └── module/                 # Reusable Route53 module
        ├── main.tf             # Zone + SOA/NS/PTR records
        └── variables.tf        # Module input variables
```



# 🚀 Quick Start

1. Prerequisites
Configure AWS Credentials

```
export AWS_ACCESS_KEY_ID="your-key"
export AWS_SECRET_ACCESS_KEY="your-secret"
export AWS_DEFAULT_REGION="us-east-1"
```
## Install Terraform :
macOS:

brew install terraform

Or download manually from:
https://developer.hashicorp.com/terraform/downloads

# Deploy the Reverse DNS Zone
Go to the zone folder:

cd route53/71.53.52.in-addr.arpa

# Initialize Terraform:

terraform init

# Preview changes:

terraform plan

Apply (this creates the hosted zone + records):

terraform apply
```
Terraform will then provision:
✔ Hosted Zone
✔ SOA Record
✔ NS Records
✔ PTR Records
```

# 🏗️ Architecture Overview
```
Root main.tf (NO resources)
        ↓ passes variables
Module main.tf (CREATES resources)
        ├── aws_route53_zone.my_reverse_zone
        ├── aws_route53_record.soa_record
        ├── aws_route53_record.ns_record
        └── aws_route53_record.ptr_record

```
# Root Main.tf
 This root module only calls the sub-module:
```
locals {
region = "us-east-1"
hosted_zone_name = "71.53.52.in-addr.arpa"

... all other locals
}

provider "aws" {
region = local.region
}

module "Route53" {
source = "./module"

hosted_zone_name = local.hosted_zone_name
soa_record_name = local.soa_record_name
soa_recordtype = local.soa_recordtype
soa_record_ttl = local.soa_record_ttl
soa_record_records = local.soa_record_records

ns_record_name = local.ns_record_name
ns_record_type = local.ns_record_type
ns_record_ttl = local.ns_record_ttl
ns_record_records = local.ns_record_records

ptr_record_name = local.ptr_record_name
ptr_record_type = local.ptr_record_type
ptr_record_ttl = local.ptr_record_ttl
ptr_record_records = local.ptr_record_records

comment = local.comment
}

✔ No AWS resources are defined here
✔ This only passes values to the module
```

# 📌 Module main.tf (Actual Resource Creation)

Example:
```
resource "aws_route53_zone" "dev" {
  name = "dev.example.com"

  tags = {
    Environment = "dev"
  }
}

resource "aws_route53_record" "dev-ns" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "dev.example.com"
  type    = "NS"
  ttl     = "30"
  records = aws_route53_zone.dev.name_servers
}
```
This main.tf create the below resources:

- ✅ **Hosted zone** with comment
- ✅ **Authoritative SOA record**  
- ✅ **Name server (NS) records** pointing to Route53 servers
- ✅ **PTR record** for reverse IP→hostname resolution (52.53.71.84 → mail.sedintechnologies.net)

## Requirements

| Name      | Version |
|-----------|---------|
| terraform | >= 1.0  |
| aws       | ~> 6.0  |

## Providers

| Name | Version |
|------|---------|
| aws  | ~> 6.0  |

## Resources

| Name                             | Type     |
|----------------------------------|----------|
| `aws_route53_zone.my_reverse_zone` | resource |
| `aws_route53_record.soa_record`  | resource |
| `aws_route53_record.ns_record`   | resource |
| `aws_route53_record.ptr_record`  | resource |

## Inputs

| Name                | Description                                                         | Type         | Default             | Required |
|---------------------|---------------------------------------------------------------------|--------------|---------------------|----------|
| `hosted_zone_name`  | Reverse DNS zone name (71.53.52.in-addr.arpa)                       | `string`     | n/a                 | yes      |
| `comment`           | Hosted zone description                                             | `string`     | "Reverse DNS Zone"  | no       |
| `soa_record_name`   | SOA record name (usually zone root)                                 | `string`     | n/a                 | yes      |
| `soa_recordtype`    | SOA record type                                                     | `string`     | "SOA"               | no       |
| `soa_record_ttl`    | SOA record TTL                                                      | `number`     | n/a                 | yes      |
| `soa_record_records`| SOA record values (MNAME RNAME serial refresh retry expire minimum) | `list(string)` | n/a              | yes      |
| `ns_record_name`    | NS record name (usually zone root)                                  | `string`     | n/a                 | yes      |
| `ns_record_type`    | NS record type                                                      | `string`     | "NS"                | no       |
| `ns_record_ttl`     | NS record TTL                                                       | `number`     | n/a                 | yes      |
| `ns_record_records` | List of Route53 name servers                                        | `list(string)` | n/a              | yes      |
| `ptr_record_name`   | PTR record name (84.71.53.52.in-addr.arpa)                          | `string`     | n/a                 | yes      |
| `ptr_record_type`   | PTR record type                                                     | `string`     | "PTR"               | no       |
| `ptr_record_ttl`    | PTR record TTL                                                      | `number`     | n/a                 | yes      |
| `ptr_record_records`| PTR target hostnames                                                | `list(string)` | n/a              | yes      |

**Usage:** `terraform init && terraform apply` creates complete reverse DNS infrastructure from root locals configuration.

## 🔗 Resources

- [AWS Route53 Reverse DNS](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/DNSConfig.html)
- [Terraform Route53 Zone](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_zone)
- [Terraform Route53 Record](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record)

---





