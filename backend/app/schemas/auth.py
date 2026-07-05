from pydantic import BaseModel, EmailStr, field_validator


class RegisterRequest(BaseModel):
    email: EmailStr
    password: str
    role: str = "company_admin"          # "company_admin" | "viewer"

    @field_validator("password")
    @classmethod
    def validate_password_strength(cls, v: str) -> str:
        if len(v) < 8:
            raise ValueError("Password must be at least 8 characters long")
        if not any(c.isalpha() for c in v):
            raise ValueError("Password must contain at least one letter")
        if not any(c.isdigit() for c in v):
            raise ValueError("Password must contain at least one number")
        return v


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class RegisterResponse(BaseModel):
    id: str
    email: str
    role: str
    message: str


class LoginResponse(BaseModel):
    """
    Response shape matching Flutter's expectations.
    Frontend stores access_token in ApiClient (mintflow.auth.token key).
    CompanyAdmin fields (id, name, email, companyName) are used to build
    the CompanyAdmin model stored in session storage.
    """
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    # CompanyAdmin fields for Flutter frontend
    id: str                               # maps to CompanyAdmin.id
    email: str                            # maps to CompanyAdmin.email
    name: str = "Company Admin"           # maps to CompanyAdmin.name
    companyName: str = "My Brand"         # maps to CompanyAdmin.companyName
    role: str


class RefreshRequest(BaseModel):
    refresh_token: str


class LogoutRequest(BaseModel):
    # Optional: the frontend currently only holds the access token (revoked via
    # the Authorization header), but a client that stores the refresh token can
    # send it here to revoke that too.
    refresh_token: str | None = None


class GoogleAuthRequest(BaseModel):
    """The Google ID token (JWT) obtained by the frontend from Google Sign-In."""
    id_token: str
