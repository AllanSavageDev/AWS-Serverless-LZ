const base = "https://api.aws-serverless.net/api-weather";
const logDiv = document.getElementById("log");

function log(msg, data) {
  logDiv.textContent += `\n${msg}`;
  if (data) logDiv.textContent += `\n${JSON.stringify(data, null, 2)}\n`;
}

async function runTest() {
  logDiv.textContent = "=== Starting API-WEATHER Test ===\n";

  const cities = ["Buenos Aires", "London", "New York", "Tokyo"];

  try {
    for (const city of cities) {
      const url = `${base}?city=${encodeURIComponent(city)}`;
      log(`Fetching weather for ${city}...`);
      const res = await fetch(url);
      const data = await res.json();
      log(`🔴 Weather for ${city}:`, data);
    }

    log("\n=== ✅ Test Complete ===");
  } catch (err) {
    log("❌ Error: " + err.message);
  }
}

document.getElementById("runTest").addEventListener("click", runTest);
