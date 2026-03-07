# Multi-Tenant Cloud Workspace Operations Platform

## Overview
This project simulates how modern cloud SaaS platforms manage multiple companies using a shared database system. Each company is treated as a **tenant**, and multiple tenants can use the same platform while keeping their data isolated.

The goal of this project is to design and implement a **multi-tenant database architecture** that supports user management, workspace creation, application deployments, resource usage tracking, and billing.

The project focuses mainly on **database design and DBMS concepts** rather than building a full frontend application.

---

## Features
- Multi-tenant architecture
- Tenant and user management
- Workspace creation and management
- Application deployments
- Resource usage tracking
- Subscription plans
- Billing and invoice generation
- Audit logging of system activities

---

## Database Concepts Used
This project demonstrates several important DBMS concepts:

- Database Normalization (1NF – 3NF)
- Primary Keys and Foreign Keys
- One-to-Many Relationships
- Constraints (NOT NULL, UNIQUE, CHECK)
- Transactions (ACID properties)
- Triggers
- Stored Procedures
- Indexing for query optimization

---

## Main Database Tables
The system is built using the following core tables:

- **tenants** – stores companies using the platform  
- **users** – stores employees of each tenant  
- **workspaces** – stores projects created by tenants  
- **deployments** – stores applications deployed in workspaces  
- **resource_usage** – tracks storage and API usage  
- **plans** – defines subscription plans  
- **invoices** – stores billing information  
- **audit_logs** – records system activity  

---

## Technologies Used
- **Database:** PostgreSQL  
- **Tools:** pgAdmin / DBeaver  
- **Version Control:** GitHub  

---

## Project Structure
cloud-workspace-dbms
│
├── README.md
├── docs
│ └── project_explanation.pdf
│
├── database
│ ├── schema.sql
│ ├── triggers.sql
│ ├── procedures.sql
│ └── demo_queries.sql
│
└── diagrams
└── er_diagram.png


---

## Purpose of the Project
The purpose of this project is to understand how real cloud platforms manage multiple customers using a shared database infrastructure while maintaining data isolation and efficient resource management.
