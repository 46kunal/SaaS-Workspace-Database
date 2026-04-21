-- ============================================================
--  SaaS Workspace Database - Full Initialization Script
--  Run this script to initialize the entire database schema
--  Usage: psql -U postgres -f database/init.sql
-- ============================================================

\encoding UTF8

-- Drop existing objects (for clean slate - optional)
-- DROP DATABASE IF EXISTS saas_workspace;
-- CREATE DATABASE saas_workspace;

-- Initialize schema
\echo '>>> Creating schema tables...'
\i database/schema.sql

-- Add constraints
\echo '>>> Adding constraints...'
\i database/constraints.sql

-- Add triggers
\echo '>>> Adding triggers...'
\i database/triggers.sql

-- Add stored procedures
\echo '>>> Adding stored procedures...'
\i database/procedures.sql

-- Add indexes
\echo '>>> Adding indexes...'
\i database/indexes.sql

-- Add sample data
\echo '>>> Inserting sample data...'
\i database/sample_data.sql

\echo ''
\echo '>>> ✅ Database initialization complete!'
\echo ''
\echo 'Quick verification:'
SELECT COUNT(*) AS total_plans FROM plans;
SELECT COUNT(*) AS total_tenants FROM tenants;
SELECT COUNT(*) AS total_tables FROM information_schema.tables WHERE table_schema = 'public';
