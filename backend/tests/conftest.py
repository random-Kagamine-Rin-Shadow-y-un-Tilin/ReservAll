import os

# `Settings()` se instancia al importar la app: hay que dejar las variables
# listas antes de importarla.
os.environ.setdefault("DATABASE_URL", "postgresql://user:pass@localhost/reservall_test")
os.environ.setdefault("JWT_SECRET", "test-secret")
os.environ.setdefault("API_KEY", "test-api-key")
os.environ.setdefault("SUPABASE_URL", "https://example.supabase.co")
os.environ.setdefault("SUPABASE_SERVICE_ROLE_KEY", "test-service-role-key")

import pytest
from fastapi.testclient import TestClient

from app.core.dependencies import get_db_pool, verify_api_key
from app.main import app


@pytest.fixture
def client():
    # Ninguna prueba de esta suite necesita PostgreSQL real.
    app.dependency_overrides[verify_api_key] = lambda: None
    app.dependency_overrides[get_db_pool] = lambda: None
    test_client = TestClient(app)
    yield test_client
    app.dependency_overrides.clear()
