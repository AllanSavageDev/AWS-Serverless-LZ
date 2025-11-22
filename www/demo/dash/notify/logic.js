const base = "https://api.aws-serverless.net/api-notify";
const logDiv = document.getElementById("log");

function log(msg, data) {
  logDiv.textContent += `\n${msg}`;
  if (data) logDiv.textContent += `\n${JSON.stringify(data, null, 2)}\n`;
}

async function runTest() {
  logDiv.textContent = "=== Starting API-NOTIFY Test ===\n";

  try {
    const postRes = await fetch(base, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        protocol: "lambda",
        endpoint: "arn:aws:lambda:us-east-1:123456789012:function:notify-handler"
        })
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

    // //If any subscriptions exist, unsubscribe the first
    // if (getData.subscriptions && getData.subscriptions.length > 0) {
    //   const arn = getData.subscriptions[0].SubscriptionArn;
    //   if (arn && arn !== "PendingConfirmation") {
    //     const delRes = await fetch(base, {
    //       method: "DELETE",
    //       headers: { "Content-Type": "application/json" },
    //       body: JSON.stringify({ subscription_arn: arn })
    //     });
    //     const delData = await delRes.json();
    //     log("🗑️ Unsubscribe result:", delData);
    //   } else {
    //     log("⚠️ No confirmed subscription to delete yet.");
    //   }
    // }

    log("\n=== ✅ Test Complete ===");
  } catch (err) {
    log("❌ Error: " + err.message);
  }
}

document.getElementById("runTest").addEventListener("click", runTest);
