const base = "https://api.aws-serverless.net/api-queue";
const logDiv = document.getElementById("log");

function log(msg, data) {
  logDiv.textContent += `\n${msg}`;
  if (data) logDiv.textContent += `\n${JSON.stringify(data, null, 2)}\n`;
}

async function runTest() {
  logDiv.textContent = "=== Starting API-QUEUE Test ===\n";

  try {
    //Send Message
    const sendRes = await fetch(base, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ message: "Hello from Lambda SQS demo" })
    });
    const sendData = await sendRes.json();
    log("🔴 Message sent:", sendData);

    //Receive Message
    const recvRes = await fetch(base);
    const recvData = await recvRes.json();
    log("🔴 Received message(s):", recvData);

    if (!recvData.length) {
      log("⚠️ No messages in queue to continue testing.");
      return;
    }

    const receiptHandle = recvData[0].ReceiptHandle;

    //Update Visibility
    const updateRes = await fetch(base, {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ receiptHandle, visibilityTimeout: 10 })
    });
    const updateData = await updateRes.json();
    log("🔴 Visibility updated:", updateData);

    //Delete Message
    const delRes = await fetch(base, {
      method: "DELETE",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ receiptHandle })
    });
    const delData = await delRes.json();
    log("🔴 Delete result:", delData);

    log("\n=== ✅ Test Complete ===");
  } catch (err) {
    log("❌ Error: " + err.message);
  }
}

document.getElementById("runTest").addEventListener("click", runTest);
