from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import asyncio
from playwright.async_api import async_playwright
from typing import Optional, Dict, Any
import os

app = FastAPI()

class PlaywrightRequest(BaseModel):
    url: str
    action: str = "basic"  # basic, click, auth
    username: Optional[str] = None
    password: Optional[str] = None
    auth_url: Optional[str] = None

class PlaywrightResponse(BaseModel):
    success: bool
    title: Optional[str] = None
    button_exists: Optional[bool] = None
    dynamic_text: Optional[str] = None
    error: Optional[str] = None

@app.get("/health")
async def health_check():
    return {"status": "ok"}

@app.post("/playwright", response_model=PlaywrightResponse)
async def run_playwright(request: PlaywrightRequest):
    try:
        async with async_playwright() as p:
            browser = await p.chromium.launch(headless=True)
            page = await browser.new_page()
            
            if request.action == "auth" and request.auth_url:
                # Handle authentication
                await page.goto(request.auth_url)
                await page.wait_for_load_state("networkidle")
                
                if request.username and request.password:
                    username_field = page.locator(
                        'input[name="username"], input[type="text"], #username'
                    )
                    password_field = page.locator(
                        'input[name="password"], input[type="password"], #password'
                    )
                    submit_button = page.locator(
                        'input[type="submit"], button[type="submit"], button:has-text("Login"), button:has-text("Sign in")'
                    )
                    
                    if await username_field.count() > 0:
                        await username_field.first.fill(request.username)
                    if await password_field.count() > 0:
                        await password_field.first.fill(request.password)
                    if await submit_button.count() > 0:
                        await submit_button.first.click()
                        await page.wait_for_load_state("networkidle")
                
                # After auth, navigate to main URL
                if request.url != request.auth_url:
                    await page.goto(request.url)
            else:
                await page.goto(request.url)
            
            # Get basic info
            title = await page.title()
            button_exists = await page.locator("#showText").count() > 0
            
            # Handle click action
            if request.action in ["click", "auth"] and button_exists:
                await page.click("#showText")
                await page.wait_for_timeout(1000)
            
            # Get dynamic text
            dynamic_text = ""
            try:
                dynamic_text = await page.text_content("#dynamicText")
            except Exception:
                pass
            
            await browser.close()
            
            return PlaywrightResponse(
                success=True,
                title=title,
                button_exists=button_exists,
                dynamic_text=dynamic_text
            )
            
    except Exception as e:
        return PlaywrightResponse(
            success=False,
            error=str(e)
        )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)