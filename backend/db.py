"""Database connection module with connection pooling."""

import os
from contextlib import contextmanager

import psycopg2
from psycopg2 import pool

# Database configuration from environment variables
DB_CONFIG = {
    "host": os.getenv("DB_HOST", "localhost"),
    "port": os.getenv("DB_PORT", "5432"),
    "database": os.getenv("DB_NAME", "saas_workspace"),
    "user": os.getenv("DB_USER", "postgres"),
    "password": os.getenv("DB_PASSWORD", "postgres"),
}

# Connection pool (initialized lazily)
_connection_pool = None


def init_pool(minconn=1, maxconn=10):
    """Initialize the connection pool."""
    global _connection_pool
    if _connection_pool is None:
        _connection_pool = pool.ThreadedConnectionPool(
            minconn, maxconn, **DB_CONFIG
        )
    return _connection_pool


def get_pool():
    """Get or create the connection pool."""
    global _connection_pool
    if _connection_pool is None:
        init_pool()
    return _connection_pool


def get_connection():
    """Get a connection from the pool."""
    return get_pool().getconn()


def release_connection(conn):
    """Return a connection to the pool."""
    get_pool().putconn(conn)


def close_pool():
    """Close all connections in the pool."""
    global _connection_pool
    if _connection_pool is not None:
        _connection_pool.closeall()
        _connection_pool = None


@contextmanager
def get_db_connection():
    """Context manager for database connections.

    Usage:
        with get_db_connection() as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT * FROM tenants")
    """
    conn = get_connection()
    try:
        yield conn
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        release_connection(conn)


@contextmanager
def get_db_cursor(commit=True):
    """Context manager for database cursor.

    Usage:
        with get_db_cursor() as cur:
            cur.execute("SELECT * FROM tenants WHERE id = %s", (tenant_id,))
            result = cur.fetchone()
    """
    with get_db_connection() as conn:
        cur = conn.cursor()
        try:
            yield cur
            if commit:
                conn.commit()
        finally:
            cur.close()
