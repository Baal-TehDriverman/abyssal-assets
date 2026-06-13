from fastapi import FastAPI, WebSocket, WebSocketDisconnect, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel, EmailStr, Field
from typing import List, Optional, Dict, Any
from datetime import datetime, timedelta
from jose import jwt, JWTError
from passlib.context import CryptContext
from sqlalchemy import create_engine, Column, Integer, String, Float, DateTime, Boolean, ForeignKey, Enum as SQLEnum
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session, relationship
import enum
import uuid
import json
import asyncio
from collections import defaultdict

# === CONFIG ===
SECRET_KEY = "abyssal-assets-secret-key-change-in-production"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24 * 7  # 1 week
DATABASE_URL = "sqlite:///./abyssal_assets.db"

# === DATABASE ===
engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# === ENUMS ===
class RarityEnum(str, enum.Enum):
    NOOB = "noob"
    COMMON = "common"
    UNCOMMON = "uncommon"
    RARE = "rare"
    EPIC = "epic"
    LEGENDARY = "legendary"
    MYTHIC = "mythic"

class ZoneEnum(str, enum.Enum):
    SHALLOWS = "shallows"
    STANDARD = "standard"
    DEEP = "deep"
    ABYSSAL = "abyssal"
    TRENCH = "trench"

class OrderSide(str, enum.Enum):
    BUY = "buy"
    SELL = "sell"

class OrderStatus(str, enum.Enum):
    OPEN = "open"
    FILLED = "filled"
    CANCELLED = "cancelled"
    PARTIAL = "partial"

# === MODELS ===
class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True, nullable=False)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    soul_coins = Column(Integer, default=1000)
    clout = Column(Integer, default=0)
    current_zone = Column(String, default="shallows")
    boat_level = Column(Integer, default=1)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    inventory = relationship("InventoryItem", back_populates="owner")
    orders = relationship("Order", back_populates="user")
    listings = relationship("MarketListing", back_populates="seller")

class Hat(Base):
    __tablename__ = "hats"
    
    id = Column(String, primary_key=True)  # e.g., "hat-soggy-visor"
    name = Column(String, nullable=False)
    rarity = Column(SQLEnum(RarityEnum), nullable=False)
    zone = Column(SQLEnum(ZoneEnum), nullable=False)
    base_buy_price = Column(Integer, nullable=False)
    base_sell_price = Column(Integer, nullable=False)
    clout_bonus = Column(Integer, default=0)
    dredge_luck = Column(Float, default=0.0)
    craft_speed = Column(Float, default=0.0)
    market_fee_reduction = Column(Float, default=0.0)
    sprite = Column(String)
    dyeable = Column(Boolean, default=False)
    particle_effect = Column(String, nullable=True)
    shader = Column(String, nullable=True)
    discontinued = Column(Boolean, default=False)
    limited_edition = Column(Boolean, default=False)
    max_supply = Column(Integer, nullable=True)
    current_supply = Column(Integer, default=0)
    description = Column(String)
    lore = Column(String)

class InventoryItem(Base):
    __tablename__ = "inventory_items"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    hat_id = Column(String, ForeignKey("hats.id"), nullable=False)
    quantity = Column(Integer, default=1)
    serial_number = Column(Integer, nullable=True)  # For limited editions
    creator_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    equipped = Column(Boolean, default=False)
    
    owner = relationship("User", back_populates="inventory", foreign_keys=[user_id])
    creator = relationship("User", foreign_keys=[creator_id])
    hat = relationship("Hat")

class Order(Base):
    __tablename__ = "orders"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    hat_id = Column(String, ForeignKey("hats.id"), nullable=False)
    side = Column(SQLEnum(OrderSide), nullable=False)
    price = Column(Integer, nullable=False)
    quantity = Column(Integer, default=1)
    filled_quantity = Column(Integer, default=0)
    status = Column(SQLEnum(OrderStatus), default=OrderStatus.OPEN)
    expires_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    user = relationship("User", back_populates="orders")
    hat = relationship("Hat")
    trades = relationship("Trade", back_populates="order")

class MarketListing(Base):
    __tablename__ = "market_listings"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    seller_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    hat_id = Column(String, ForeignKey("hats.id"), nullable=False)
    price = Column(Integer, nullable=False)
    quantity = Column(Integer, default=1)
    duration_hours = Column(Integer, default=24)
    created_at = Column(DateTime, default=datetime.utcnow)
    expires_at = Column(DateTime, nullable=False)
    is_active = Column(Boolean, default=True)
    sold_quantity = Column(Integer, default=0)
    
    seller = relationship("User", back_populates="listings")
    hat = relationship("Hat")

class Trade(Base):
    __tablename__ = "trades"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    buy_order_id = Column(String, ForeignKey("orders.id"), nullable=False)
    sell_order_id = Column(String, ForeignKey("orders.id"), nullable=False)
    hat_id = Column(String, ForeignKey("hats.id"), nullable=False)
    price = Column(Integer, nullable=False)
    quantity = Column(Integer, nullable=False)
    buyer_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    seller_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    fee_paid = Column(Integer, default=0)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    buy_order = relationship("Order", foreign_keys=[buy_order_id])
    sell_order = relationship("Order", foreign_keys=[sell_order_id])
    hat = relationship("Hat")

class DredgeLog(Base):
    __tablename__ = "dredge_logs"
    
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    zone = Column(SQLEnum(ZoneEnum), nullable=False)
    depth = Column(Integer, nullable=False)
    success = Column(Boolean, nullable=False)
    precision = Column(Float, nullable=True)
    items_found = Column(String, nullable=True)  # JSON array
    clout_gained = Column(Integer, default=0)
    xp_gained = Column(Integer, default=0)
    created_at = Column(DateTime, default=datetime.utcnow)

# === SCHEMAS ===
class UserCreate(BaseModel):
    username: str = Field(..., min_length=3, max_length=20)
    email: EmailStr
    password: str = Field(..., min_length=8)

class UserLogin(BaseModel):
    username: str
    password: str

class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"

class TokenData(BaseModel):
    user_id: Optional[int] = None

class HatResponse(BaseModel):
    id: str
    name: str
    rarity: RarityEnum
    zone: ZoneEnum
    base_buy_price: int
    base_sell_price: int
    clout_bonus: int
    dredge_luck: float
    sprite: Optional[str]
    discontinued: bool
    limited_edition: bool
    description: Optional[str]

class InventoryItemResponse(BaseModel):
    id: int
    hat: HatResponse
    quantity: int
    serial_number: Optional[int]
    equipped: bool

class OrderCreate(BaseModel):
    hat_id: str
    side: OrderSide
    price: int = Field(..., gt=0)
    quantity: int = Field(1, ge=1)
    expires_hours: Optional[int] = None

class OrderResponse(BaseModel):
    id: str
    hat_id: str
    side: OrderSide
    price: int
    quantity: int
    filled_quantity: int
    status: OrderStatus
    created_at: datetime

class MarketListingCreate(BaseModel):
    hat_id: str
    price: int = Field(..., gt=0)
    quantity: int = Field(1, ge=1)
    duration_hours: int = Field(24, ge=1, le=168)

class MarketListingResponse(BaseModel):
    id: str
    hat: HatResponse
    seller_username: str
    price: int
    quantity: int
    remaining_quantity: int
    expires_at: datetime

class MarketItemSummary(BaseModel):
    id: str
    name: str
    rarity: RarityEnum
    buy_price: int
    sell_price: int
    volume_24h: int
    price_change_24h: float
    listings_count: int

class DredgeRequest(BaseModel):
    zone: ZoneEnum
    boat_level: int = 1

class DredgeResult(BaseModel):
    success: bool
    items: List[InventoryItemResponse] = []
    clout_gained: int
    xp_gained: int
    precision: Optional[float] = None

class MarketStats(BaseModel):
    total_volume_24h: int
    total_listings: int
    top_gainers: List[MarketItemSummary]
    top_losers: List[MarketItemSummary]

# === AUTH ===
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
security = HTTPBearer()

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password: str) -> str:
    return pwd_context.hash(password)

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

def decode_token(token: str) -> TokenData:
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id: int = payload.get("sub")
        if user_id is None:
            raise HTTPException(status_code=401, detail="Invalid token")
        return TokenData(user_id=user_id)
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid token")

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

async def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security), db: Session = Depends(get_db)) -> User:
    token_data = decode_token(credentials.credentials)
    user = db.query(User).filter(User.id == token_data.user_id).first()
    if user is None:
        raise HTTPException(status_code=401, detail="User not found")
    return user

# === APP ===
app = FastAPI(
    title="Abyssal Assets API",
    description="The Loch Exchange - Cryptid Hat Trading Simulator API",
    version="0.1.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "http://localhost:8000", "http://127.0.0.1:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Create tables
Base.metadata.create_all(bind=engine)

# === WEBSOCKET MANAGER ===
class ConnectionManager:
    def __init__(self):
        self.active_connections: Dict[int, List[WebSocket]] = defaultdict(list)
        self.market_subscribers: List[WebSocket] = []
    
    async def connect(self, websocket: WebSocket, user_id: int):
        await websocket.accept()
        self.active_connections[user_id].append(websocket)
    
    def disconnect(self, websocket: WebSocket, user_id: int):
        if websocket in self.active_connections[user_id]:
            self.active_connections[user_id].remove(websocket)
    
    async def send_personal_message(self, message: dict, user_id: int):
        for ws in self.active_connections[user_id]:
            try:
                await ws.send_json(message)
            except:
                pass
    
    async def broadcast_market(self, message: dict):
        for ws in self.market_subscribers:
            try:
                await ws.send_json(message)
            except:
                pass
    
    def subscribe_market(self, websocket: WebSocket):
        self.market_subscribers.append(websocket)
    
    def unsubscribe_market(self, websocket: WebSocket):
        if websocket in self.market_subscribers:
            self.market_subscribers.remove(websocket)

manager = ConnectionManager()

# === UTILS ===
def get_zone_depth(zone: ZoneEnum) -> int:
    depths = {
        ZoneEnum.SHALLOWS: 50,
        ZoneEnum.STANDARD: 200,
        ZoneEnum.DEEP: 500,
        ZoneEnum.ABYSSAL: 1500,
        ZoneEnum.TRENCH: 3000,
    }
    return depths.get(zone, 50)

def get_rarity_color(rarity: RarityEnum) -> str:
    colors = {
        RarityEnum.NOOB: "#666666",
        RarityEnum.COMMON: "#ffffff",
        RarityEnum.UNCOMMON: "#00ff88",
        RarityEnum.RARE: "#0088ff",
        RarityEnum.EPIC: "#8800ff",
        RarityEnum.LEGENDARY: "#ffd700",
        RarityEnum.MYTHIC: "#ff00ff",
    }
    return colors.get(rarity, "#ffffff")

# === ROUTES ===

# Auth
@app.post("/api/auth/register", response_model=Token)
async def register(user_data: UserCreate, db: Session = Depends(get_db)):
    # Check existing
    if db.query(User).filter(User.username == user_data.username).first():
        raise HTTPException(400, "Username taken")
    if db.query(User).filter(User.email == user_data.email).first():
        raise HTTPException(400, "Email registered")
    
    # Create user
    user = User(
        username=user_data.username,
        email=user_data.email,
        hashed_password=get_password_hash(user_data.password),
        soul_coins=1000,
        clout=0,
        current_zone="shallows",
        boat_level=1,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    
    # Give starter hat
    starter_hat = db.query(Hat).filter(Hat.id == "hat-soggy-visor").first()
    if starter_hat:
        inv = InventoryItem(user_id=user.id, hat_id=starter_hat.id, quantity=1)
        db.add(inv)
        db.commit()
    
    token = create_access_token({"sub": user.id})
    return {"access_token": token, "token_type": "bearer"}

@app.post("/api/auth/login", response_model=Token)
async def login(credentials: UserLogin, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.username == credentials.username).first()
    if not user or not verify_password(credentials.password, user.hashed_password):
        raise HTTPException(status_code=401, detail="Invalid credentials")
    
    token = create_access_token({"sub": user.id})
    return {"access_token": token, "token_type": "bearer"}

@app.get("/api/auth/me")
async def get_me(current_user: User = Depends(get_current_user)):
    return {
        "id": current_user.id,
        "username": current_user.username,
        "email": current_user.email,
        "soul_coins": current_user.soul_coins,
        "clout": current_user.clout,
        "current_zone": current_user.current_zone,
        "boat_level": current_user.boat_level,
    }

# Hats
@app.get("/api/hats", response_model=List[HatResponse])
async def get_hats(rarity: Optional[RarityEnum] = None, zone: Optional[ZoneEnum] = None, db: Session = Depends(get_db)):
    query = db.query(Hat)
    if rarity:
        query = query.filter(Hat.rarity == rarity)
    if zone:
        query = query.filter(Hat.zone == zone)
    return query.all()

@app.get("/api/hats/{hat_id}", response_model=HatResponse)
async def get_hat(hat_id: str, db: Session = Depends(get_db)):
    hat = db.query(Hat).filter(Hat.id == hat_id).first()
    if not hat:
        raise HTTPException(404, "Hat not found")
    return hat

# Inventory
@app.get("/api/inventory", response_model=List[InventoryItemResponse])
async def get_inventory(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    items = db.query(InventoryItem).filter(InventoryItem.user_id == current_user.id).all()
    return [
        InventoryItemResponse(
            id=item.id,
            hat=HatResponse.from_orm(item.hat),
            quantity=item.quantity,
            serial_number=item.serial_number,
            equipped=item.equipped,
        )
        for item in items
    ]

# Dredging
@app.post("/api/dredge", response_model=DredgeResult)
async def dredge(request: DredgeRequest, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    # Validate zone access
    zone_clout_req = {
        ZoneEnum.SHALLOWS: 0,
        ZoneEnum.STANDARD: 100,
        ZoneEnum.DEEP: 500,
        ZoneEnum.ABYSSAL: 1000,
        ZoneEnum.TRENCH: 10000,
    }
    if current_user.clout < zone_clout_req[request.zone]:
        raise HTTPException(403, f"Need {zone_clout_req[request.zone]} resonance for {request.zone}")
    
    # Simulate dredge (in reality, client runs mini-game and sends precision)
    import random
    precision = random.uniform(0.3, 1.0)  # Simulated
    
    # Simple loot generation
    zone_items = {
        ZoneEnum.SHALLOWS: ["hat-soggy-visor", "hat-plastic-horns", "hat-wet-cardboard", "hat-wool-beanie"],
        ZoneEnum.STANDARD: ["hat-wool-beanie", "hat-fisherman-cap", "hat-kelp-crown", "hat-kelp-top-hat"],
        ZoneEnum.DEEP: ["hat-kelp-top-hat", "hat-sub-captain-cap", "hat-coral-tiara", "hat-admiral-bicorn"],
        ZoneEnum.ABYSSAL: ["hat-admiral-bicorn", "hat-pearl-fedora", "hat-seaweed-sombrero", "hat-plundered-captain-cap"],
        ZoneEnum.TRENCH: ["hat-plundered-captain-cap", "hat-kraken-ink-stetson", "hat-abyssal-crown", "hat-surgeons-photograph"],
    }
    
    possible_items = zone_items.get(request.zone, ["hat-soggy-visor"])
    chosen_id = random.choice(possible_items)
    hat = db.query(Hat).filter(Hat.id == chosen_id).first()
    
    if hat:
        # Add to inventory
        inv = db.query(InventoryItem).filter(InventoryItem.user_id == 1, InventoryItem.hat_id == chosen_id).first()
        if inv:
            inv.quantity += 1
        else:
            inv = InventoryItem(user_id=1, hat_id=chosen_id, quantity=1)
            db.add(inv)
        
        clout_gained = random.randint(5, 20)
        xp = clout_gained * 2
        
        current_user.clout += clout_gained
        current_user.soul_coins += 10
        db.commit()
        
        return DredgeResult(
            success=True,
            items=[{
                "id": inv.id,
                "hat": {
                    "id": hat.id,
                    "name": hat.name,
                    "rarity": hat.rarity,
                    "zone": hat.zone,
                    "base_buy_price": hat.base_buy_price,
                    "base_sell_price": hat.base_sell_price,
                    "clout_bonus": hat.clout_bonus,
                    "dredge_luck": hat.dredge_luck,
                    "sprite": hat.sprite,
                    "discontinued": hat.discontinued,
                    "limited_edition": hat.limited_edition,
                    "description": hat.description,
                },
                "quantity": inv.quantity,
                "serial_number": inv.serial_number,
                "equipped": inv.equipped,
            }],
            clout_gained=clout_gained,
            xp_gained=clout_gained * 2,
            precision=round(random.uniform(0.5, 1.0), 2)
        )
    
    return DredgeResult(success=False, items=[], clout_gained=0, xp_gained=0)

# Orders
@app.post("/api/orders", response_model=OrderResponse)
async def create_order(order: OrderCreate, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    hat = db.query(Hat).filter(Hat.id == order.hat_id).first()
    if not hat:
        raise HTTPException(404, "Hat not found")
    
    total_cost = order.price * order.quantity
    
    if order.side == OrderSide.BUY:
        total_cost = int(total_cost * 1.03)  # 3% fee
        if current_user.soul_coins < total_cost:
            raise HTTPException(400, "Insufficient soul coins")
        current_user.soul_coins -= total_cost
    else:
        # Check inventory
        inv = db.query(InventoryItem).filter(
            InventoryItem.user_id == current_user.id,
            InventoryItem.hat_id == order.hat_id,
            InventoryItem.equipped == False
        ).first()
        if not inv or inv.quantity < order.quantity:
            raise HTTPException(400, "Insufficient items in inventory")
        inv.quantity -= order.quantity
    
    order_obj = Order(
        user_id=current_user.id,
        hat_id=order.hat_id,
        side=order.side,
        price=order.price,
        quantity=order.quantity,
        expires_at=datetime.utcnow() + timedelta(hours=order.expires_hours) if order.expires_hours else None,
    )
    db.add(order)
    db.commit()
    db.refresh(order_obj)
    return order_obj

@app.get("/api/orders", response_model=List[OrderResponse])
async def get_orders(status_filter: Optional[OrderStatus] = None, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    query = db.query(Order).filter(Order.user_id == current_user.id)
    if status_filter:
        query = query.filter(Order.status == status_filter)
    return query.order_by(Order.created_at.desc()).all()

@app.delete("/api/orders/{order_id}")
async def cancel_order(order_id: str, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    order = db.query(Order).filter(Order.id == order_id, Order.user_id == current_user.id).first()
    if not order:
        raise HTTPException(404, "Order not found")
    if order.status != OrderStatus.OPEN:
        raise HTTPException(400, "Cannot cancel non-open order")
    
    # Refund
    if order.side == OrderSide.BUY:
        refund = (order.price * order.quantity) * 1.03
        current_user.soul_coins += int(refund)
    else:
        # Return items to inventory
        inv = db.query(InventoryItem).filter(
            InventoryItem.user_id == current_user.id,
            InventoryItem.hat_id == order.hat_id
        ).first()
        if inv:
            inv.quantity += order.quantity - order.filled_quantity
        else:
            inv = InventoryItem(user_id=current_user.id, hat_id=order.hat_id, quantity=order.quantity - order.filled_quantity)
            db.add(inv)
    
    order.status = OrderStatus.CANCELLED
    db.commit()
    return {"message": "Order cancelled"}

# Market Listings
@app.post("/api/listings", response_model=MarketListingResponse)
async def create_listing(listing: MarketListingCreate, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    hat = db.query(Hat).filter(Hat.id == listing.hat_id).first()
    if not hat:
        raise HTTPException(404, "Hat not found")
    
    # Check inventory
    inv = db.query(InventoryItem).filter(
        InventoryItem.user_id == current_user.id,
        InventoryItem.hat_id == listing.hat_id,
        InventoryItem.equipped == False
    ).first()
    if not inv or inv.quantity < listing.quantity:
        raise HTTPException(400, "Insufficient items")
    
    inv.quantity -= listing.quantity
    
    ml = MarketListing(
        seller_id=current_user.id,
        hat_id=listing.hat_id,
        price=listing.price,
        quantity=listing.quantity,
        duration_hours=listing.duration_hours,
        expires_at=datetime.utcnow() + timedelta(hours=listing.duration_hours),
    )
    db.add(ml)
    db.commit()
    db.refresh(ml)
    
    return MarketListingResponse(
        id=ml.id,
        hat={
            "id": hat.id,
            "name": hat.name,
            "rarity": hat.rarity,
            "zone": hat.zone,
            "base_buy_price": hat.base_buy_price,
            "base_sell_price": hat.base_sell_price,
            "clout_bonus": hat.clout_bonus,
            "dredge_luck": hat.dredge_luck,
            "sprite": hat.sprite,
            "discontinued": hat.discontinued,
            "limited_edition": hat.limited_edition,
            "description": hat.description,
        },
        seller_username="you",
        price=ml.price,
        quantity=ml.quantity,
        remaining_quantity=ml.quantity - ml.sold_quantity,
        expires_at=ml.expires_at,
    )

@app.get("/api/listings", response_model=List[MarketListingResponse])
async def get_listings(active_only: bool = True, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    query = db.query(MarketListing).join(Hat).filter(MarketListing.seller_id == current_user.id)
    if active_only:
        query = query.filter(MarketListing.is_active == True, MarketListing.expires_at > datetime.utcnow())
    
    results = []
    for ml in query.all():
        results.append(MarketListingResponse(
            id=ml.id,
            hat={
                "id": ml.hat.id,
                "name": ml.hat.name,
                "rarity": ml.hat.rarity,
                "zone": ml.hat.zone,
                "base_buy_price": ml.hat.base_buy_price,
                "base_sell_price": ml.hat.base_sell_price,
                "clout_bonus": ml.hat.clout_bonus,
                "dredge_luck": ml.hat.dredge_luck,
                "sprite": ml.hat.sprite,
                "discontinued": ml.hat.discontinued,
                "limited_edition": ml.hat.limited_edition,
                "description": ml.hat.description,
            },
            seller_username="you",
            price=ml.price,
            quantity=ml.quantity,
            remaining_quantity=ml.quantity - ml.sold_quantity,
            expires_at=ml.expires_at,
        ))
    return results

# Market Data
@app.get("/api/market", response_model=List[MarketItemSummary])
async def get_market(db: Session = Depends(get_db)):
    # Generate market summary from orders
    # Simplified - in reality would aggregate from order book
    hats = db.query(Hat).all()
    result = []
    
    for hat in hats:
        # Calculate 24h stats (simplified)
        volume = 0  # Would aggregate from trades
        change = 0.0  # Would calculate from price history
        
        result.append(MarketItemSummary(
            id=hat.id,
            name=hat.name,
            rarity=hat.rarity,
            buy_price=hat.base_buy_price,
            sell_price=hat.base_sell_price,
            volume_24h=0,  # TODO
            price_change_24h=0.0,  # TODO
            listings_count=db.query(MarketListing).filter(MarketListing.hat_id == hat.id, MarketListing.is_active == True).count(),
        ))
    return result

@app.get("/api/market/stats", response_model=MarketStats)
async def get_market_stats(db: Session = Depends(get_db)):
    return MarketStats(
        total_volume_24h=0,
        total_listings=db.query(MarketListing).filter(MarketListing.is_active == True).count(),
        top_gainers=[],
        top_losers=[],
    )

# WebSocket
@app.websocket("/ws/market")
async def websocket_market(websocket: WebSocket):
    await manager.connect(websocket, user_id=0)  # Anonymous market data
    manager.subscribe_market(websocket)
    try:
        while True:
            data = await websocket.receive_json()
            # Handle subscribe/unsubscribe to specific items
    except WebSocketDisconnect:
        manager.unsubscribe_market(websocket)

@app.websocket("/ws/user/{user_id}")
async def websocket_user(websocket: WebSocket, user_id: int):
    await manager.connect(websocket, user_id)
    try:
        while True:
            data = await websocket.receive_json()
            # Handle user-specific events
    except WebSocketDisconnect:
        manager.disconnect(websocket, user_id)

# Leaderboard
@app.get("/api/leaderboard/clout")
async def clout_leaderboard(limit: int = 50, db: Session = Depends(get_db)):
    users = db.query(User).order_by(User.clout.desc()).limit(limit).all()
    return [{"rank": i+1, "username": u.username, "clout": u.clout, "zone": u.current_zone} for i, u in enumerate(users)]

@app.get("/api/leaderboard/wealth")
async def wealth_leaderboard(limit: int = 50, db: Session = Depends(get_db)):
    users = db.query(User).order_by(User.soul_coins.desc()).limit(limit).all()
    return [{"rank": i+1, "username": u.username, "coins": u.soul_coins} for i, u in enumerate(users)]

# Health
@app.get("/health")
async def health():
    return {"status": "healthy", "service": "abyssal-assets-api"}

# Startup - Seed database
@app.on_event("startup")
async def startup():
    db = SessionLocal()
    try:
        # Check if hats exist
        if not db.query(Hat).first():
            seed_hats(db)
        print("Database seeded")
    finally:
        db.close()

def seed_hats(db: Session):
    hats_data = [
        # NOOB
        Hat(id="hat-soggy-visor", name="Soggy Tourist Visor", rarity=RarityEnum.NOOB, zone=ZoneEnum.SHALLOWS, base_buy_price=10, base_sell_price=5, description="A damp visor from a confused tourist."),
        Hat(id="hat-plastic-horns", name="Plastic Viking Horns", rarity=RarityEnum.NOOB, zone=ZoneEnum.SHALLOWS, base_buy_price=15, base_sell_price=8, description="Cheap costume horns. Historically inaccurate."),
        Hat(id="hat-wet-cardboard", name="Wet Cardboard Crown", rarity=RarityEnum.NOOB, zone=ZoneEnum.SHALLOWS, base_buy_price=5, base_sell_price=2, description="Literally trash. But it's a crown."),
        
        # COMMON
        Hat(id="hat-wool-beanie", name="Wool Beanie", rarity=RarityEnum.COMMON, zone=ZoneEnum.SHALLOWS, base_buy_price=120, base_sell_price=60, clout_bonus=5, description="Warm. Practical. Respectable."),
        Hat(id="hat-fisherman-cap", name="Fisherman's Cap", rarity=RarityEnum.COMMON, zone=ZoneEnum.SHALLOWS, base_buy_price=200, base_sell_price=100, dredge_luck=0.05, description="Smells like salt and patience."),
        Hat(id="hat-kelp-crown", name="Kelp Crown", rarity=RarityEnum.COMMON, zone=ZoneEnum.SHALLOWS, base_buy_price=350, base_sell_price=175, craft_speed=0.1, description="Woven from the Loch's own fibers."),
        
        # UNCOMMON
        Hat(id="hat-kelp-top-hat", name="Kelp-Woven Top Hat", rarity=RarityEnum.UNCOMMON, zone=ZoneEnum.STANDARD, base_buy_price=2500, base_sell_price=1250, clout_bonus=10, description="Elegant. Alchemical fibers shimmer."),
        Hat(id="hat-sub-captain-cap", name="Submarine Captain's Cap", rarity=RarityEnum.UNCOMMON, zone=ZoneEnum.STANDARD, base_buy_price=5000, base_sell_price=2500, dredge_luck=0.1, description="Worn by those who navigate the deep."),
        Hat(id="hat-coral-tiara", name="Coral Tiara", rarity=RarityEnum.UNCOMMON, zone=ZoneEnum.STANDARD, base_buy_price=3200, base_sell_price=1600, craft_speed=0.15, description="Living coral. Still growing."),
        
        # RARE
        Hat(id="hat-admiral-bicorn", name="Admiral's Bicorn", rarity=RarityEnum.RARE, zone=ZoneEnum.DEEP, base_buy_price=25000, base_sell_price=12500, clout_bonus=25, description="Salty brass. Commands respect."),
        Hat(id="hat-pearl-fedora", name="Pearl-Studded Fedora", rarity=RarityEnum.RARE, zone=ZoneEnum.DEEP, base_buy_price=35000, base_sell_price=17500, clout_bonus=30, description="Each pearl a memory of the deep."),
        Hat(id="hat-seaweed-sombrero", name="Enchanted Seaweed Sombrero", rarity=RarityEnum.RARE, zone=ZoneEnum.DEEP, base_buy_price=28000, base_sell_price=14000, dredge_luck=0.2, description="Wide brim catches the currents."),
        
        # EPIC
        Hat(id="hat-plundered-captain-cap", name="Plundered Captain's Cap", rarity=RarityEnum.EPIC, zone=ZoneEnum.ABYSSAL, base_buy_price=150000, base_sell_price=75000, clout_bonus=100, dredge_luck=0.3, description="Stolen from a ghost fleet. Still smells of gunpowder."),
        Hat(id="hat-kraken-ink-stetson", name="Kraken Ink Stetson", rarity=RarityEnum.EPIC, zone=ZoneEnum.ABYSSAL, base_buy_price=250000, base_sell_price=125000, clout_bonus=150, dredge_luck=0.4, description="Dyed in the black blood of the deep."),
        Hat(id="hat-abyssal-crown", name="Abyssal Crown", rarity=RarityEnum.EPIC, zone=ZoneEnum.ABYSSAL, base_buy_price=500000, base_sell_price=250000, clout_bonus=200, craft_speed=0.3, description="Pressure-forged. Weighs nothing. Feels like destiny."),
        
        # LEGENDARY
        Hat(id="hat-surgeons-photograph", name="1934 Surgeon's Photograph", rarity=RarityEnum.LEGENDARY, zone=ZoneEnum.TRENCH, base_buy_price=5000000, base_sell_price=2500000, clout_bonus=1000, discontinued=True, limited_edition=True, max_supply=100, description="The photo that fooled the world. The hat that didn't."),
        Hat(id="hat-neptunes-trident-helm", name="Neptune's Trident Helm", rarity=RarityEnum.LEGENDARY, zone=ZoneEnum.TRENCH, base_buy_price=10000000, base_sell_price=5000000, clout_bonus=2500, description="Forged in the heart of a hydrothermal vent."),
        
        # MYTHIC
        Hat(id="hat-nessies-crown", name="Nessie's Lost Crown", rarity=RarityEnum.MYTHIC, zone=ZoneEnum.TRENCH, base_buy_price=0, base_sell_price=0, clout_bonus=10000, discontinued=True, limited_edition=True, max_supply=1, description="The crown the Queen lost. The Loch remembers."),
        Hat(id="hat-original-monster-hat", name="The Original 1933 Monster Hunter's Hat", rarity=RarityEnum.MYTHIC, zone=ZoneEnum.TRENCH, base_buy_price=0, base_sell_price=0, clout_bonus=10000, discontinued=True, limited_edition=True, max_supply=1, description="Worn by the first to see Her. The hat that started it all."),
    ]
    
    for hat in hats_data:
        db.merge(hat)
    db.commit()
    print(f"Seeded {len(hats_data)} hats")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)