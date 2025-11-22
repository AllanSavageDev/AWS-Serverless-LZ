const base = "https://api.aws-serverless.net/api-notify";
const logDiv = document.getElementById("log");

async function fetchLogs() {
  const logDiv = document.getElementById("log");
  logDiv.textContent = "Loading...";

  try {
    const res = await fetch("https://api.aws-serverless.net/api-log");
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    const data = await res.json();

    let output = "";
    output += "TIME".padEnd(40) + "IP".padEnd(18) + "EVENT".padEnd(40) + "PAGE".padEnd(25) + "REFERRER\n";
    output += "-".repeat(150) + "\n";

    renderLogs(data);

  } catch (err) {
    logDiv.textContent = "Error fetching logs: " + err.message;
  }
}

function renderLogs(data) {
  const container = document.getElementById("log");
  container.innerHTML = "";

  const header = `
    <div class="log-row log-header">
      <div>TIME</div><div>IP</div><div>EVENT</div><div>PAGE</div><div>REFERRER</div>
    </div>`;
  container.insertAdjacentHTML("beforeend", header);

  data.forEach(item => {
    container.insertAdjacentHTML(
      "beforeend",
      `<div class="log-row">
         <div>${item["@timestamp"] || ""}</div>
         <div>${item.ip || ""}</div>
         <div>${item.event || ""}</div>
         <div>${item.page || ""}</div>
         <div>${item.referer || ""}</div>
       </div>`
    );
  });
}

function log(msg, data) {
  logDiv.textContent += `\n${msg}`;
  if (data) logDiv.textContent += `\n${JSON.stringify(data, null, 2)}\n`;
}

async function runTest() {
  logDiv.textContent = "=== Starting API-NOTIFY Test ===\n";

  try {
    //Publish a message
    const postRes = await fetch(base, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ message: "Test notification from browser" })
    });
    const postData = await postRes.json();
    log("🔴 Published message:", postData);

    //List subscriptions
    const getRes = await fetch(base);
    const getData = await getRes.json();
    log("🔴 Current subscriptions:", getData);

    //Subscribe (email example)
    const putRes = await fetch(base, {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ protocol: "email", endpoint: "test@example.com" })
    });
    const putData = await putRes.json();
    log("🔴 Subscription request:", putData);

    //If any subscriptions exist, unsubscribe the first
    if (getData.subscriptions && getData.subscriptions.length > 0) {
      const arn = getData.subscriptions[0].SubscriptionArn;
      if (arn && arn !== "PendingConfirmation") {
        const delRes = await fetch(base, {
          method: "DELETE",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ subscription_arn: arn })
        });
        const delData = await delRes.json();
        log("🗑️ Unsubscribe result:", delData);
      } else {
        log("⚠️ No confirmed subscription to delete yet.");
      }
    }

    log("\n=== ✅ Test Complete ===");
  } catch (err) {
    log("❌ Error: " + err.message);
  }
}

