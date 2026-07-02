from pydantic import BaseModel
from typing import List
import uuid


class AnswerItem(BaseModel):
    question_id: uuid.UUID
    response_value: str


class SubmitInteractionRequest(BaseModel):
    answers: List[AnswerItem]
