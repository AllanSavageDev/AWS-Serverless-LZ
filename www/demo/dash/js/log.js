// js/log.js
async function logEvent(eventName, pagePath) {
  try {
    const payload = {
      event: eventName,
      page: pagePath || window.location.pathname
    };

    await fetch("https://api.aws-serverless.net/api-log", {
      method: "POST",
      headers: {
        "Content-Type": "application/json"
      },
      body: JSON.stringify(payload)
    });
  } catch (err) {
    // fail silently; don't block the page
    console.error("logEvent error:", err);
  }
}

// Automatically log page load
document.addEventListener("DOMContentLoaded", () => {
  logEvent(`page_load_${window.location.pathname.replace(/\//g, "_")}`, window.location.pathname);
});

document.addEventListener("click", (e) => {
  if( e.target.localName=='label')
  {
    const label = e.target;  
    const tag = label.innerText.replace(/\s+/g, "_");

    console.log("stop");
    logEvent(tag, window.location.pathname);
  }
  else{
    return;
  }
  });
