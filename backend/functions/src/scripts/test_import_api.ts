import * as admin from "firebase-admin";
import axios from "axios";
import * as logger from "firebase-functions/logger";

// Initialize Firebase Admin SDK
const serviceAccount = require("/Users/benniejoseph/Documents/CenthiosV2/ai/serviceAccountKey.json");
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: `https://cenithos.firebaseio.com`,
});

const API_BASE_URL = "http://127.0.0.1:5001/cenithos/us-central1/api";

async function testTransactionImport() {
  // IMPORTANT: Replace with a fresh, valid ID token from your test user
  const authToken =
    "eyJhbGciOiJSUzI1NiIsImtpZCI6ImE4ZGY2MmQzYTBhNDRlM2RmY2RjYWZjNmRhMTM4Mzc3NDU5ZjliMDEiLCJ0eXAiOiJKV1QifQ.eyJuYW1lIjoidGVzdGVyIFFBIiwiaXNzIjoiaHR0cHM6Ly9zZWN1cmV0b2tlbi5nb29nbGUuY29tL2Nlbml0aG9zIiwiYXVkIjoiY2VuaXRob3MiLCJhdXRoX3RpbWUiOjE3NTI0OTI4NTEsInVzZXJfaWQiOiJ3T0xHRnBiRkFWYW9rMTJ4RFdiZ29qQ0NkbVYyIiwic3ViIjoid09MR0ZwYkZBVmFvazEyeERXYmdvakNDZG1WMiIsImlhdCI6MTc1MjUwMzY2MCwiZXhwIjoxNzUyNTA3MjYwLCJlbWFpbCI6InRlc3RlcnFhQGV4YW1wbGUuY29tIiwiZW1haWxfdmVyaWZpZWQiOmZhbHNlLCJmaXJlYmFzZSI6eyJpZGVudGl0aWVzIjp7ImVtYWlsIjpbInRlc3RlcnFhQGV4YW1wbGUuY29tIl19LCJzaWduX2luX3Byb3ZpZGVyIjoicGFzc3dvcmQifX0.TewCF4aDklknmgtErndxqLs-UXW4-cUZ90AlrY3quXzcP5RJp3Cg-XVrH026vuATK6D9zo4aLdkSe8Lv_cklSksTzrR7p6t7vcaqYRSPX9SQptJomjp_gBeqvyxHHHAhnttascO91rgsAp9UPFqJAMjHHo-ImCp93m21_u5CVAI-H2UNWJlB0jIT7salqhsZH6RkyYr-uCfUqTCHWCpvymSd6vY8zU-SJyswD1RLMDx_y4NzbI6-uBqObxNWUnZ8WopQzUt4f-tKwPTFRdfsCizlR_vFcyu5uJy7CuX_60ThF94AjHpGEMncAuE1bjaXSCY4N36HcImJpAOrltNpgQ";

  if (!authToken) {
    logger.error(
      "Auth token is missing. Please sign in to the app and paste a valid ID token."
    );
    return;
  }

  const transactionsPayload = {
    transactions: [
      {
        amount: 150.0,
        currency: "INR",
        description: "Test Transaction 1",
        category: "Shopping",
        merchant: "test.merchant.1@upi",
        vendor: "Test Vendor 1",
        bank: "Test Bank",
        date: new Date().toISOString(),
        type: "expense",
        ref_id: `test_${Date.now()}_1`,
        source: "sms-ai",
      },
      {
        amount: 25.5,
        currency: "INR",
        description: "Test Transaction 2",
        category: "Food",
        merchant: "test.merchant.2@upi",
        vendor: "Test Vendor 2",
        bank: "Test Bank",
        date: new Date().toISOString(),
        type: "expense",
        ref_id: `test_${Date.now()}_2`,
        source: "sms-ai",
      },
    ],
  };

  try {
    logger.info("Sending request to /api/transactions/import with payload:", {
      payload: transactionsPayload,
    });
    const response = await axios.post(
      `${API_BASE_URL}/transactions/import`,
      transactionsPayload,
      {
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${authToken}`,
        },
      }
    );

    logger.info("Response from /api/transactions/import:", {
      status: response.status,
      data: response.data,
    });
  } catch (error: any) {
    logger.error("Error calling /api/transactions/import:", {
      message: error.message,
      response: error.response ? {
        status: error.response.status,
        data: error.response.data
      } : "No response from server",
    });
  }
}

testTransactionImport(); 