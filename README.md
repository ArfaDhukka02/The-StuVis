# The Stu-Vis — Cloud-Deployed 3-Tier Student Analytics Platform

A full-stack analytics dashboard deployed on AWS EC2, built with a 3-tier containerized architecture.

## Architecture

```
Client Browser
      │
      ▼
  NGINX (Port 8080)          ← Reverse proxy / static file server
      │
      ▼
  Flask API (Port 5000)      ← RESTful analytics backend
      │
      ▼
  MySQL 8.0                  ← Relational database (500+ student records)
```

All three services are containerized with Docker and orchestrated via Docker Compose.

## Features

- **6 data visualizations** rendered with Chart.js:
  1. Average GPA by Major (bar chart)
  2. Students per Major (doughnut chart)
  3. GPA Distribution Histogram
  4. Top 10 Students Leaderboard (horizontal bar)
  5. Enrollment by Major (horizontal bar)
  6. Search & Filter Student Cards (live filtering)
- **5 REST API endpoints** serving analytics data from MySQL
- **500+ student records** seeded across 8 academic majors
- NGINX configured as a reverse proxy routing `/api/*` routes to the Flask backend

## API Endpoints

| Endpoint | Description |
|---|---|
| `GET /students` | All students (supports `?major=` filter) |
| `GET /students/top` | Top N students by GPA (supports `?limit=`) |
| `GET /analytics/gpa-by-major` | Average GPA per major |
| `GET /analytics/gpa-distribution` | GPA bucket distribution |
| `GET /analytics/summary` | Total students, avg/min/max GPA |
| `GET /analytics/students-per-major` | Enrollment count per major |

## Infrastructure as Code (Terraform)

All AWS infrastructure is provisioned with Terraform — no manual console configuration.

```
terraform/
├── main.tf        # VPC, subnets, IGW, EC2, RDS, security groups
├── variables.tf   # Input variables (region, AMI, DB credentials)
└── outputs.tf     # EC2 public IP/DNS, RDS endpoint
```

**Resources provisioned:**
- VPC with public subnet (EC2) and two private subnets (RDS Multi-AZ)
- Internet Gateway + route table
- EC2 security group (ports 22, 80, 8080)
- RDS security group (port 3306, EC2-only inbound)
- EC2 `t2.micro` instance with Docker bootstrap user_data script
- RDS MySQL 8.0 `db.t3.micro` instance (private, not publicly accessible)

```bash
cd terraform
terraform init
export TF_VAR_db_password="yourpassword"
terraform plan
terraform apply
```

## Run Locally

```bash
docker compose up --build
```

Then open: http://localhost:8080

## Tech Stack

- **Cloud:** AWS EC2, RDS (MySQL 8.0)
- **Infrastructure as Code:** Terraform (EC2, VPC, security groups, RDS)
- **Containers:** Docker, Docker Compose
- **Backend:** Python, Flask, mysql-connector-python
- **Frontend:** HTML, CSS, JavaScript, Chart.js
- **Proxy:** NGINX (reverse proxy + static file serving)
- **Database:** MySQL 8.0
