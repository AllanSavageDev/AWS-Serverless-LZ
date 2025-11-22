const base = "https://api.aws-serverless.net/api-todo";
const logDiv = document.getElementById("log");

function log(msg, data) {
  logDiv.textContent += `\n${msg}`;
  if (data) logDiv.textContent += `\n${JSON.stringify(data, null, 2)}\n`;
}

async function runTest() {
  logDiv.textContent = "=== Starting API-TODO Test ===\n";

  try {
    //Create
    const createRes = await fetch(base, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ task: "buy milk", ttl_seconds: 600 })
    });
    const createData = await createRes.json();
    const id = createData.item.id;
    log(`🔴 Created task ID ${id}`, createData);

    //List all
    const list1 = await fetch(base);
    log("🔴 Tasks after create:", await list1.json());

    //Update
    const updateRes = await fetch(base, {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ id, task: "buy milk and eggs", done: true })
    });
    log("🔴 Update result:", await updateRes.json());

    //List all again
    const list2 = await fetch(base);
    log("🔴 Tasks after update:", await list2.json());

    //Delete
    const delRes = await fetch(`${base}/${id}`, { method: "DELETE" });
    log("🔴 Delete result:", await delRes.json());

    //Final list
    const list3 = await fetch(base);
    log("🔴 Final tasks:", await list3.json());

    log("\n=== ✅ Test Complete ===");
  } catch (err) {
    log("❌ Error: " + err.message);
  }
}

document.getElementById("runTest").addEventListener("click", runTest);
