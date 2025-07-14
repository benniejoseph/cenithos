"use strict";
var __assign = (this && this.__assign) || function () {
    __assign = Object.assign || function(t) {
        for (var s, i = 1, n = arguments.length; i < n; i++) {
            s = arguments[i];
            for (var p in s) if (Object.prototype.hasOwnProperty.call(s, p))
                t[p] = s[p];
        }
        return t;
    };
    return __assign.apply(this, arguments);
};
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __generator = (this && this.__generator) || function (thisArg, body) {
    var _ = { label: 0, sent: function() { if (t[0] & 1) throw t[1]; return t[1]; }, trys: [], ops: [] }, f, y, t, g = Object.create((typeof Iterator === "function" ? Iterator : Object).prototype);
    return g.next = verb(0), g["throw"] = verb(1), g["return"] = verb(2), typeof Symbol === "function" && (g[Symbol.iterator] = function() { return this; }), g;
    function verb(n) { return function (v) { return step([n, v]); }; }
    function step(op) {
        if (f) throw new TypeError("Generator is already executing.");
        while (g && (g = 0, op[0] && (_ = 0)), _) try {
            if (f = 1, y && (t = op[0] & 2 ? y["return"] : op[0] ? y["throw"] || ((t = y["return"]) && t.call(y), 0) : y.next) && !(t = t.call(y, op[1])).done) return t;
            if (y = 0, t) op = [op[0] & 2, t.value];
            switch (op[0]) {
                case 0: case 1: t = op; break;
                case 4: _.label++; return { value: op[1], done: false };
                case 5: _.label++; y = op[1]; op = [0]; continue;
                case 7: op = _.ops.pop(); _.trys.pop(); continue;
                default:
                    if (!(t = _.trys, t = t.length > 0 && t[t.length - 1]) && (op[0] === 6 || op[0] === 2)) { _ = 0; continue; }
                    if (op[0] === 3 && (!t || (op[1] > t[0] && op[1] < t[3]))) { _.label = op[1]; break; }
                    if (op[0] === 6 && _.label < t[1]) { _.label = t[1]; t = op; break; }
                    if (t && _.label < t[2]) { _.label = t[2]; _.ops.push(op); break; }
                    if (t[2]) _.ops.pop();
                    _.trys.pop(); continue;
            }
            op = body.call(thisArg, _);
        } catch (e) { op = [6, e]; y = 0; } finally { f = t = 0; }
        if (op[0] & 5) throw op[1]; return { value: op[0] ? op[1] : void 0, done: true };
    }
};
Object.defineProperty(exports, "__esModule", { value: true });
var admin = require("firebase-admin");
var firestore_1 = require("firebase-admin/firestore");
// Initialize the Firebase Admin SDK
// IMPORTANT: Make sure your GOOGLE_APPLICATION_CREDENTIALS environment variable
// is set correctly to point to your service account key file.
try {
    admin.initializeApp({
        credential: admin.credential.applicationDefault(),
    });
}
catch (error) {
    if (error instanceof Error && error.message.includes("already exists")) {
        // This is fine, means we're probably in an environment where it's already initialized.
    }
    else {
        throw error;
    }
}
var db = (0, firestore_1.getFirestore)();
var findDuplicateTransactions = function () { return __awaiter(void 0, void 0, void 0, function () {
    var transactionsSnapshot, transactions, groups, _i, transactions_1, tx, dateString, key, duplicateIdsToDelete, potentialDuplicateGroups, _a, _b, _c, key, group, transactionToKeep, transactionsToDelete;
    var _d;
    return __generator(this, function (_e) {
        switch (_e.label) {
            case 0:
                console.log("Fetching all transactions from the database...");
                return [4 /*yield*/, db.collection("transactions").get()];
            case 1:
                transactionsSnapshot = _e.sent();
                transactions = transactionsSnapshot.docs.map(function (doc) { return (__assign({ id: doc.id }, doc.data())); });
                console.log("Found ".concat(transactions.length, " total transactions. Analyzing for duplicates..."));
                groups = new Map();
                for (_i = 0, transactions_1 = transactions; _i < transactions_1.length; _i++) {
                    tx = transactions_1[_i];
                    dateString = void 0;
                    if (typeof tx.date === 'string') {
                        dateString = tx.date.substring(0, 10);
                    }
                    else if (tx.date instanceof admin.firestore.Timestamp) {
                        dateString = tx.date.toDate().toISOString().substring(0, 10);
                    }
                    else if (tx.date && typeof tx.date === 'object' && '_seconds' in tx.date) {
                        dateString = new Date(tx.date._seconds * 1000).toISOString().substring(0, 10);
                    }
                    else {
                        console.warn("Skipping transaction ".concat(tx.id, " due to invalid date format."));
                        continue;
                    }
                    key = "".concat(tx.userId, "-").concat(dateString, "-").concat(tx.amount, "-").concat((tx.description || tx.ref_id || "").trim());
                    if (!groups.has(key)) {
                        groups.set(key, []);
                    }
                    groups.get(key).push(tx);
                }
                duplicateIdsToDelete = [];
                potentialDuplicateGroups = 0;
                console.log("\n--- Potential Duplicate Groups ---");
                for (_a = 0, _b = groups.entries(); _a < _b.length; _a++) {
                    _c = _b[_a], key = _c[0], group = _c[1];
                    if (group.length > 1) {
                        potentialDuplicateGroups++;
                        // Sort by createdAt timestamp, newest first. Keep the newest one.
                        group.sort(function (a, b) {
                            var _a, _b, _c, _d;
                            var timeA = (_b = (_a = a.createdAt) === null || _a === void 0 ? void 0 : _a.toMillis()) !== null && _b !== void 0 ? _b : 0;
                            var timeB = (_d = (_c = b.createdAt) === null || _c === void 0 ? void 0 : _c.toMillis()) !== null && _d !== void 0 ? _d : 0;
                            return timeB - timeA;
                        });
                        transactionToKeep = group[0];
                        transactionsToDelete = group.slice(1);
                        console.log("\nGroup Key: ".concat(key));
                        console.log("  Keeping: ".concat(transactionToKeep.id, " (Created at: ").concat((_d = transactionToKeep.createdAt) === null || _d === void 0 ? void 0 : _d.toDate().toISOString(), ")"));
                        transactionsToDelete.forEach(function (tx) {
                            var _a;
                            console.log("  Marking for deletion: ".concat(tx.id, " (Created at: ").concat((_a = tx.createdAt) === null || _a === void 0 ? void 0 : _a.toDate().toISOString(), ")"));
                            duplicateIdsToDelete.push(tx.id);
                        });
                    }
                }
                if (potentialDuplicateGroups === 0) {
                    console.log("\nNo duplicate transaction groups found.");
                }
                else {
                    console.log("\nFound ".concat(potentialDuplicateGroups, " groups with potential duplicates."));
                    console.log("A total of ".concat(duplicateIdsToDelete.length, " transactions have been marked for deletion."));
                    console.log("\n--- IDs to Delete ---");
                    console.log(JSON.stringify(duplicateIdsToDelete, null, 2));
                    console.log("\nTo delete these transactions, run the delete-duplicates script with this list.");
                }
                return [2 /*return*/];
        }
    });
}); };
findDuplicateTransactions().catch(console.error);
