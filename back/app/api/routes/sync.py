from fastapi import APIRouter, Depends, HTTPException
from app.services.dendreo_sync import DendreoSyncService
import logging
from app.services.dendreo_client import DendreoClient
import httpx

logger = logging.getLogger(__name__)
router = APIRouter()

@router.post("/sync-all")
async def sync_all():
    """Sync all data from Dendreo API"""
    try:
        service = DendreoSyncService()
        result = await service.sync_all_data()
        return result
    except Exception as e:
        logger.error(f"Sync failed: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/test-sync")
async def test_sync():
    """Test sync with small dataset"""
    try:
        service = DendreoSyncService()
        result = await service.test_sync_small()
        return result
    except Exception as e:
        logger.error(f"Test sync failed: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

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
