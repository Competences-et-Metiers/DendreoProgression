from fastapi import APIRouter, HTTPException
import httpx
from app.config.settings import settings

router = APIRouter()

@router.get("/test-dendreo")
async def test_dendreo_connection():
    """Test connection to Dendreo API"""
    try:
        url = f"{settings.dendreo_base_url}/lmps.php"
        params = {
            "key": settings.dendreo_api_key,
            "include": "participant,module"
        }

        async with httpx.AsyncClient() as client:
            response = await client.get(url, params=params)

        if response.status_code == 200:
            data = response.json()
            return {
                "status": "success",
                "message": "Successfully connected to Dendreo API",
                "lmps_count": len(data.get("lmps", [])),
                "sample_data": data.get("lmps", [])[:2]  # Return first 2 LMPs as sample
            }
        else:
            raise HTTPException(
                status_code=response.status_code,
                detail=f"Dendreo API returned status {response.status_code}"
            )

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error connecting to Dendreo API: {str(e)}")

@router.post("/sync-dendreo")
async def sync_from_dendreo():
    """Sync data from Dendreo API to local database"""
    try:
        # This will be implemented later
        return {
            "status": "not_implemented",
            "message": "Sync functionality will be implemented in next steps"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error syncing data: {str(e)}")
