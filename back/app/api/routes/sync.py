from fastapi import APIRouter, HTTPException
import httpx
import logging
from app.config.settings import settings
from app.services.dendreo_sync import DendreoSyncService

router = APIRouter()
sync_service = DendreoSyncService()
logger = logging.getLogger(__name__)

@router.get("/test-dendreo")
async def test_dendreo_connection():
    """Test connection to Dendreo API laps.php endpoint with API key from env"""
    try:
        base_url = settings.dendreo_base_url
        api_key = settings.dendreo_api_key

        print(f"🔍 Testing Dendreo Connection:")
        print(f"   Base URL: {base_url}")
        print(f"   API Key: {api_key[:10] if api_key else 'NOT_SET'}...")

        if not api_key:
            print("   ❌ API Key not found in environment variables")
            raise HTTPException(status_code=500, detail="API Key not configured")

        # Test the laps.php endpoint with API key from environment
        test_url = f"{base_url.rstrip('/')}/laps.php?key={api_key}&id_action_de_formation=115"

        print(f"   Testing URL: {base_url.rstrip('/')}/laps.php?key=***&id_action_de_formation=115")

        async with httpx.AsyncClient(timeout=15.0, follow_redirects=True) as client:
            print("   🌐 Making request to Dendreo laps.php endpoint...")
            response = await client.get(test_url)

        print(f"   ✅ Response status: {response.status_code}")
        print(f"   📄 Content type: {response.headers.get('content-type', 'unknown')}")
        print(f"   🔗 Final URL: {str(response.url).replace(api_key, '***')}")
        print(f"   📐 Content length: {len(response.text)} characters")

        # Show redirect history if any
        if hasattr(response, 'history') and response.history:
            print(f"   🔄 Redirects: {len(response.history)} redirect(s)")
            for i, hist_response in enumerate(response.history):
                location = hist_response.headers.get('location', 'unknown')
                # Mask the API key in redirect URLs too
                if api_key in location:
                    location = location.replace(api_key, '***')
                print(f"      {i+1}. {hist_response.status_code} -> {location}")

        # Show content preview
        content_preview = response.text[:500]
        print(f"   📝 Content preview: {content_preview}...")

        # Try to parse JSON
        is_json = False
        json_data = None
        try:
            json_data = response.json()
            is_json = True
            print(f"   ✅ Response is valid JSON")

            if isinstance(json_data, dict):
                print(f"   🔑 JSON keys: {list(json_data.keys())}")

                # Show some key information if available
                if "nb_participants" in json_data:
                    print(f"   👥 Number of participants: {json_data.get('nb_participants', 'unknown')}")
                if "nb_modules" in json_data:
                    print(f"   📚 Number of modules: {json_data.get('nb_modules', 'unknown')}")
                if "participants" in json_data and isinstance(json_data["participants"], list):
                    print(f"   👤 Participants list length: {len(json_data['participants'])}")
                if "modules" in json_data and isinstance(json_data["modules"], list):
                    print(f"   📖 Modules list length: {len(json_data['modules'])}")

            elif isinstance(json_data, list):
                print(f"   📋 JSON is a list with {len(json_data)} items")

        except Exception as json_error:
            print(f"   ❌ Response is not valid JSON: {str(json_error)}")

        # Mask API key in response URLs
        safe_final_url = str(response.url).replace(api_key, '***') if api_key else str(response.url)
        safe_content_preview = content_preview.replace(api_key, '***') if api_key else content_preview

        return {
            "status": "success" if response.status_code == 200 else "error",
            "message": f"Response from Dendreo laps.php endpoint",
            "status_code": response.status_code,
            "final_url": safe_final_url,
            "content_type": response.headers.get("content-type", "unknown"),
            "content_preview": safe_content_preview,
            "content_length": len(response.text),
            "is_json": is_json,
            "json_keys": list(json_data.keys()) if is_json and isinstance(json_data, dict) else None,
            "json_summary": {
                "participants_count": json_data.get("nb_participants") if is_json and isinstance(json_data, dict) else None,
                "modules_count": json_data.get("nb_modules") if is_json and isinstance(json_data, dict) else None,
                "has_participants_list": "participants" in json_data if is_json and isinstance(json_data, dict) else False,
                "has_modules_list": "modules" in json_data if is_json and isinstance(json_data, dict) else False,
            } if is_json else None,
            "redirects": len(response.history) if hasattr(response, 'history') else 0
        }

    except httpx.TimeoutException:
        print("   ⏰ Timeout connecting to Dendreo API")
        raise HTTPException(status_code=408, detail="Timeout connecting to Dendreo API")
    except Exception as e:
        print(f"   💥 Error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error connecting to Dendreo API: {str(e)}")



@router.get("/debug-settings")
async def debug_settings():
    """Debug endpoint to check settings"""
    return {
        "dendreo_base_url": settings.dendreo_base_url,
        "dendreo_api_key_length": len(settings.dendreo_api_key) if settings.dendreo_api_key else 0,
        "dendreo_api_key_start": settings.dendreo_api_key[:10] if settings.dendreo_api_key else "NOT_SET",
        "database_url_set": bool(settings.database_url)
    }
