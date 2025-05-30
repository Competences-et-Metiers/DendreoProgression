from fastapi import APIRouter, Depends, HTTPException
from app.services.dendreo_sync import DendreoSync
from app.services.dendreo_client import DendreoClient
from app.models.database import get_db
from sqlalchemy.orm import Session
from typing import Dict, Any
import logging
import httpx

logger = logging.getLogger(__name__)
router = APIRouter()

@router.post("/sync-all")
async def sync_all(db: Session = Depends(get_db)) -> Dict[str, Any]:
    """Synchronize all data from Dendreo"""
    try:
        client = DendreoClient()
        sync_service = DendreoSync(db, client)
        await sync_service.sync_all()
        return {"status": "success", "message": "Sync completed successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Sync failed: {str(e)}")

@router.post("/sync-test")
async def sync_test(db: Session = Depends(get_db)) -> Dict[str, Any]:
    """Test sync with a small dataset"""
    try:
        client = DendreoClient()
        sync_service = DendreoSync(db, client)
        result = await sync_service.test_sync_small()
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Test sync failed: {str(e)}")

@router.get("/test-api")
async def test_api():
    """Test API connection"""
    try:
        client = DendreoClient()
        url = f"{client.base_url}/lmps.php"
        params = {'key': client.api_key, 'include': 'participant,module'}

        async with httpx.AsyncClient() as http_client:
            response = await http_client.head(url, params=params, timeout=10.0)
            return {
                "status": "success" if response.status_code == 200 else "error",
                "status_code": response.status_code,
                "message": "API connection test"
            }
    except Exception as e:
        return {"status": "error", "message": str(e)}
