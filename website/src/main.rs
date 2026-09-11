use axum::{
    body::Body,
    http::{header, HeaderMap, StatusCode},
    response::{Html, IntoResponse, Redirect, Response},
    routing::get,
    Router,
};
use std::net::SocketAddr;
use tower_http::cors::CorsLayer;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

// Embed static HTML and PNG asset into the binary at compile time
static INDEX_HTML: &str = include_str!("templates/index.html");
static DEATH_STAR_PNG: &[u8] = include_bytes!("../assets/deathstar.png");

// PowerShell Quick-Install Script served directly to terminal / curl / irm requests
static POWERSHELL_RUN_SCRIPT: &str = r#"<#
    .SYNOPSIS
    STARDEBLOAT Quick Bootstrapper
    Downloads and executes stardebloat directly from GitHub repository.
#>
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$repoUrl = "https://raw.githubusercontent.com/promotezzz/STARDEBLOATER/main/Scripts/Get.ps1"
Write-Host ">>> STARDEBLOAT: Downloading Imperial Bootstrapper..." -ForegroundColor Red

try {
    $script = (Invoke-RestMethod -Uri $repoUrl -UseBasicParsing)
    & ([scriptblock]::Create($script)) @args
}
catch {
    Write-Error "Failed to download stardebloat bootstrapper: $($_.Exception.Message)"
}
"#;

#[tokio::main]
async fn main() {
    // Initialize logging
    tracing_subscriber::registry()
        .with(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| "stardebloat_website=info,tower_http=info".into()),
        )
        .with(tracing_subscriber::fmt::layer())
        .init();

    let app = Router::new()
        .route("/", get(root_handler))
        .route("/run", get(powershell_script_handler))
        .route("/install", get(powershell_script_handler))
        .route("/assets/deathstar.png", get(deathstar_image_handler))
        .route("/download", get(download_redirect_handler))
        .route("/health", get(health_handler))
        .layer(CorsLayer::permissive());

    let port: u16 = std::env::var("PORT")
        .ok()
        .and_then(|p| p.parse().ok())
        .unwrap_or(8080);

    let addr = SocketAddr::from(([0, 0, 0, 0], port));
    println!();
    println!("======================================================");
    println!("   STARDEBLOAT Minimal Rust Showcase Server");
    println!("======================================================");
    println!("-> Listening on: http://localhost:{port}");
    println!("-> Network:      http://{addr}");
    println!("-> Endpoints:");
    println!("     GET /             - Landing Page / Auto-CLI detect");
    println!("     GET /run          - PowerShell Quick Launcher");
    println!("     GET /download     - Redirect to GitHub ZIP release");
    println!("     GET /health       - Healthcheck (200 OK)");
    println!("======================================================");
    println!();

    let listener = tokio::net::TcpListener::bind(addr)
        .await
        .expect("Failed to bind to socket address");

    axum::serve(listener, app)
        .await
        .expect("Server encountered a fatal runtime error");
}

/// Root handler: inspects User-Agent.
/// If accessed via PowerShell / curl / wget, returns the install script.
/// Otherwise, returns the Death Star themed HTML landing page.
async fn root_handler(headers: HeaderMap) -> Response {
    if let Some(user_agent) = headers.get(header::USER_AGENT).and_then(|v| v.to_str().ok()) {
        let ua_lower = user_agent.to_lowercase();
        if ua_lower.contains("powershell") || ua_lower.starts_with("curl/") || ua_lower.starts_with("wget/") {
            return powershell_script_handler().await.into_response();
        }
    }

    // Dynamic host replacement for copy-pastable install command
    let host = headers
        .get(header::HOST)
        .and_then(|h| h.to_str().ok())
        .unwrap_or("stardebloat.com");

    let scheme = if host.starts_with("localhost") || host.starts_with("127.0.0.1") {
        "http"
    } else {
        "https"
    };

    let origin = format!("{scheme}://{host}");
    let html = INDEX_HTML.replace("https://stardebloat.com", &origin);

    Html(html).into_response()
}

/// Serves the raw PowerShell script
async fn powershell_script_handler() -> Response {
    Response::builder()
        .status(StatusCode::OK)
        .header(header::CONTENT_TYPE, "text/plain; charset=utf-8")
        .header(header::CACHE_CONTROL, "no-cache, no-store, must-revalidate")
        .body(Body::from(POWERSHELL_RUN_SCRIPT))
        .unwrap_or_else(|_| StatusCode::INTERNAL_SERVER_ERROR.into_response())
}

/// Serves the embedded Death Star PNG image
async fn deathstar_image_handler() -> Response {
    Response::builder()
        .status(StatusCode::OK)
        .header(header::CONTENT_TYPE, "image/png")
        .header(header::CACHE_CONTROL, "public, max-age=86400")
        .body(Body::from(DEATH_STAR_PNG))
        .unwrap_or_else(|_| StatusCode::INTERNAL_SERVER_ERROR.into_response())
}

/// Redirects to GitHub ZIP archive
async fn download_redirect_handler() -> Redirect {
    Redirect::temporary("https://github.com/promotezzz/STARDEBLOATER/archive/refs/heads/main.zip")
}

/// Health check endpoint for uptime monitors
async fn health_handler() -> &'static str {
    "OK"
}
