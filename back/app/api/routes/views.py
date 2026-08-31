from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session
from app.models.database import get_db
from app.models.models import User, UserView
from app.models.schemas import UserViewCreate, UserViewResponse
from app.auth.dependencies import get_current_user
from typing import List
import logging

logger = logging.getLogger(__name__)
router = APIRouter()

MAX_VIEWS_PER_USER = 20


@router.get("/", response_model=List[UserViewResponse])
def list_views(
    page: str = Query("inactive"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    views = db.query(UserView).filter(
        UserView.user_id == current_user.id,
        UserView.page == page,
    ).order_by(UserView.updated_at.desc()).all()
    return views


@router.post("/", response_model=UserViewResponse, status_code=201)
def create_view(
    payload: UserViewCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    count = db.query(UserView).filter(
        UserView.user_id == current_user.id,
        UserView.page == payload.page,
    ).count()
    if count >= MAX_VIEWS_PER_USER:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Maximum {MAX_VIEWS_PER_USER} saved views allowed"
        )

    view = UserView(
        user_id=current_user.id,
        page=payload.page,
        name=payload.name.strip(),
        filter_config=payload.filter_config,
    )
    db.add(view)
    db.commit()
    db.refresh(view)
    logger.info(f"User '{current_user.username}' created view '{view.name}' on page '{view.page}' (id={view.id})")
    return view


@router.put("/{view_id}", response_model=UserViewResponse)
def update_view(
    view_id: int,
    payload: UserViewCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    view = db.query(UserView).filter(
        UserView.id == view_id,
        UserView.user_id == current_user.id,
    ).first()
    if not view:
        raise HTTPException(status_code=404, detail="View not found")
    view.name = payload.name.strip()
    view.filter_config = payload.filter_config
    view.page = payload.page
    db.commit()
    db.refresh(view)
    logger.info(f"User '{current_user.username}' updated view '{view.name}' on page '{view.page}' (id={view.id})")
    return view


@router.delete("/{view_id}", status_code=204)
def delete_view(
    view_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    view = db.query(UserView).filter(
        UserView.id == view_id,
        UserView.user_id == current_user.id,
    ).first()
    if not view:
        raise HTTPException(status_code=404, detail="View not found")
    db.delete(view)
    db.commit()
    logger.info(f"User '{current_user.username}' deleted view '{view.name}' (id={view_id})")
