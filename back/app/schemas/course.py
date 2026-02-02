from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime

class ModuleResponse(BaseModel):
    id: int
    id_lmp: str
    id_lam: str
    intitule: Optional[str] = None
    progression: float
    last_access_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True

class CourseResponse(BaseModel):
    id: int
    id_action_formation: str
    id_lam: str
    intitule: str
    status: str
    mode_organisation: Optional[str] = None
    hubspot_transaction_url: Optional[str] = None
    hubspot_transaction_id: Optional[str] = None
    total_modules: int = 0  # Total number of e-learning modules in the course
    progression: float = 0.0  # Average progression across all modules
    last_access_at: Optional[datetime] = None  # Latest access across all modules
    modules: List[ModuleResponse] = []
    
    class Config:
        from_attributes = True 