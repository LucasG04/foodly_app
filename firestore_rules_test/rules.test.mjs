// Mirrors the app's Firestore calls (foodly_app/lib/services) against ../firestore.rules.
// Run with `npm install && npm test` (needs the firebase CLI and Java 21+).
import { readFileSync } from "node:fs";
import { test, before, beforeEach, after } from "node:test";
import { assertFails, assertSucceeds, initializeTestEnvironment } from "@firebase/rules-unit-testing";
import firebase from "firebase/compat/app";
import "firebase/compat/firestore";
import { collection, getAggregateFromServer, sum } from "firebase/firestore";

const { FieldValue, FieldPath } = firebase.firestore;
let env;
const as = (uid) => (uid ? env.authenticatedContext(uid) : env.unauthenticatedContext()).firestore();

const planMap = (o = {}) => ({
  name: "Home", code: "AbCd1234", users: ["alice"], hourDiffToUtc: 2,
  adFree: false, locked: false, lastUserJoined: 1, ...o,
});
const mealMap = (o = {}) => ({
  name: "Lasagne", source: null, instructions: "", duration: 30, servings: 2, ingredients: [],
  tags: ["pasta"], imageUrl: "", imageCredit: null, planId: "p1", createdBy: "alice",
  isPublic: false, createdAt: 1, kcal: null, ...o,
});
const userMap = (o = {}) => ({
  oldPlans: ["p1"], isPremium: null, isPremiumGifted: null, premiumGiftedAt: null,
  premiumGiftedMonths: null, premiumGiftedMessageShown: null, aiConsentAt: null, role: "user", ...o,
});

before(async () => {
  env = await initializeTestEnvironment({
    projectId: "demo-foodly",
    firestore: { rules: readFileSync(new URL("../firestore.rules", import.meta.url), "utf8") },
  });
});
after(() => env.cleanup());
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await db.doc("plans/p1").set(planMap());
    await db.doc("plans/p1/meals/pm1").set({ date: 0, meal: "m1", type: "MealType.DINNER", upvotes: [] });
    await db.doc("plans/p1/mealHistory/pm0").set({ date: 0, meal: "m1", type: "MealType.DINNER" });
    await db.doc("plans/p1/stats/s1").set({ mealId: "m1", plannedCount: 1, lastTimePlanned: 1 });
    await db.doc("plans/p2").set(planMap({ name: "Other", code: "Zz999999", users: ["carol"] }));
    // Legacy plan: flags null/missing, no name.
    await db.doc("plans/legacy").set({ code: "Leg00000", users: ["carol"], locked: null, adFree: null });
    await db.doc("plans/locked").set(planMap({ code: "Lck00000", users: ["carol"], locked: true }));
    await db.doc("meals/m1").set(mealMap());
    await db.doc("meals/m2").set(mealMap({ planId: "p2", createdBy: "carol" }));
    await db.doc("meals/legacyMeal").set(mealMap({ isPublic: null }));
    await db.doc("meals/pub").set(mealMap({ planId: "old", isPublic: true }));
    await db.doc("shoppinglists/sl1").set({ planId: "p1", meals: [] });
    await db.doc("shoppinglists/sl1/groceries/g1").set({ name: "Milk", bought: false, lastBoughtEdited: 0 });
    await db.doc("users/alice").set(userMap());
    await db.doc("users/gifted").set(userMap({ isPremiumGifted: true, premiumGiftedAt: 5, premiumGiftedMonths: 1200 }));
    await db.doc("users/legacyRole").set(userMap({ role: "FoodlyUserRole.user" }));
    await db.doc("aiUsage/alice").set({ periodKey: "x", textUsed: 1 });
    await db.doc("library_meals/l1").set({ name: "x" });
    await db.doc("versions/v").set({ v: 1 });
    await db.doc("mcpTokens/alice").set({ hash: "h", createdAt: 1 });
    await db.doc("users/admin").set(userMap({ role: "admin" }));
    await db.doc("feedbacks/f1").set({ userId: "alice", title: "Hi", date: 1 });
    await db.doc("logs/l1").set({ message: "x" });
    await db.doc("changes/c1").set({ version: "1.0.0", text: "x" });
    await db.doc("missingGroceries/mg1").set({ count: 12, groupSuggestion: null });
  });
});

// --- plans -------------------------------------------------------------------
test("code lookup works before sign-in", () =>
  assertSucceeds(as(null).collection("plans").where("code", "==", "AbCd1234").limit(1).get()));
test("getCurrentPlanId", () =>
  assertSucceeds(as("alice").collection("plans").where("users", "array-contains", "alice").limit(1).get()));
test("getPlansByIds (documentId in)", () =>
  assertSucceeds(as("bob").collection("plans").where(FieldPath.documentId(), "in", ["p1", "p2"]).get()));

test("createPlan batch: plan + shopping list + user.oldPlans", async () => {
  const db = as("alice");
  const b = db.batch();
  const plan = db.collection("plans").doc();
  b.set(plan, planMap({ code: "New00000" }));
  b.set(db.collection("shoppinglists").doc(), { meals: [], planId: plan.id });
  b.update(db.doc("users/alice"), { oldPlans: FieldValue.arrayUnion(plan.id) });
  await assertSucceeds(b.commit());
});
test("create plan with other members denied", () =>
  assertFails(as("alice").collection("plans").add(planMap({ users: ["alice", "bob"] }))));
test("create adFree plan denied", () =>
  assertFails(as("alice").collection("plans").add(planMap({ adFree: true }))));
test("shopping list for a foreign plan denied", () =>
  assertFails(as("alice").collection("shoppinglists").add({ meals: [], planId: "p2" })));

test("join: full-map updatePlan adding self", () =>
  assertSucceeds(as("bob").doc("plans/p1").update(planMap({ users: ["alice", "bob"], lastUserJoined: 99 }))));
test("join legacy plan (null/missing fields come back as defaults)", () =>
  assertSucceeds(as("bob").doc("plans/legacy").update({
    name: null, code: "Leg00000", users: ["carol", "bob"], hourDiffToUtc: 0,
    adFree: false, locked: false, lastUserJoined: 99,
  })));
test("join locked plan denied", () =>
  assertFails(as("bob").doc("plans/locked").update(planMap({ code: "Lck00000", users: ["carol", "bob"], locked: true }))));
test("join adding someone else denied", () =>
  assertFails(as("bob").doc("plans/p1").update(planMap({ users: ["alice", "bob", "eve"] }))));
test("join renaming plan denied", () =>
  assertFails(as("bob").doc("plans/p1").update(planMap({ name: "Mine", users: ["alice", "bob"] }))));
test("join changing code denied", () =>
  assertFails(as("bob").doc("plans/p1").update(planMap({ code: "Hijacked", users: ["alice", "bob"] }))));
test("join setting adFree denied", () =>
  assertFails(as("bob").doc("plans/p1").update(planMap({ adFree: true, users: ["alice", "bob"] }))));

test("member rename / code / lock (full map)", () =>
  assertSucceeds(as("alice").doc("plans/p1").update(planMap({ name: "New", code: "New11111", locked: true }))));
test("member leaves (leavePlan)", () =>
  assertSucceeds(as("alice").doc("plans/p1").update({ users: [], locked: false })));
test("member removes someone else / adds someone denied", async () => {
  await env.withSecurityRulesDisabled((ctx) => ctx.firestore().doc("plans/p2").update({ users: ["carol", "dave"] }));
  await assertFails(as("carol").doc("plans/p2").update({ users: ["carol"] }));
  await assertFails(as("carol").doc("plans/p2").update({ users: ["carol", "dave", "eve"] }));
});
test("member rewriting users from a stale plan denied", async () => {
  await env.withSecurityRulesDisabled((ctx) => ctx.firestore().doc("plans/p1").update({ users: ["alice", "bob"] }));
  await assertFails(as("alice").doc("plans/p1").update(planMap({ name: "Renamed" })));
});
test("updatePlanFields: rename / code / lock", async () => {
  const plan = as("alice").doc("plans/p1");
  await assertSucceeds(plan.update({ name: "Renamed" }));
  await assertSucceeds(plan.update({ code: "New22222" }));
  await assertSucceeds(plan.update({ locked: true }));
});
test("member sets adFree denied", () =>
  assertFails(as("alice").doc("plans/p1").update({ adFree: true })));
test("member update on legacy plan with adFree null", () =>
  assertSucceeds(as("carol").doc("plans/legacy").update({
    name: "Named", code: "Leg00000", users: ["carol"], hourDiffToUtc: 0, adFree: false, locked: false, lastUserJoined: 0,
  })));
test("delete plan denied", () => assertFails(as("alice").doc("plans/p1").delete()));

// --- plan subcollections -------------------------------------------------------
test("member streams plan meals", () => assertSucceeds(as("alice").collection("plans/p1/meals").get()));
test("member adds/updates/deletes plan meal", async () => {
  const db = as("alice");
  const ref = await assertSucceeds(db.collection("plans/p1/meals").add({ date: 1, meal: "m1", type: "MealType.LUNCH", upvotes: [] }));
  await assertSucceeds(db.doc("plans/p1/meals/pm1").set({ upvotes: ["alice"] }, { merge: true }));
  await assertSucceeds(ref.delete());
});
test("member history + stats queries", async () => {
  const db = as("alice");
  await assertSucceeds(db.collection("plans/p1/mealHistory").get());
  await assertSucceeds(db.doc("plans/p1/mealHistory/pm1").set({ date: 0, meal: "m1" }));
  await assertSucceeds(db.collection("plans/p1/stats").orderBy("plannedCount").limit(5).get());
  await assertSucceeds(db.collection("plans/p1/stats").where("mealId", "==", "m1").get());
  // MealStatService.getPlannedTotal (paywall)
  await assertSucceeds(getAggregateFromServer(collection(db._delegate, "plans/p1/stats"), { total: sum("plannedCount") }));
  await assertSucceeds(db.collection("plans/p1/stats").add({ mealId: "m9", plannedCount: 0, lastTimePlanned: 1 }));
});
test("non-member reads plan meals denied", () => assertFails(as("bob").collection("plans/p1/meals").get()));
test("signed-out reads plan meals denied", () => assertFails(as(null).collection("plans/p1/meals").get()));
test("member writes libraryImports denied", () => assertFails(as("alice").doc("plans/p1/libraryImports/x").set({})));

// --- meals ------------------------------------------------------------------------
test("meal reads: by id, documentId in, by planId, isPublic", async () => {
  const db = as("alice");
  await assertSucceeds(db.doc("meals/m2").get());
  await assertSucceeds(db.collection("meals").where(FieldPath.documentId(), "in", ["m1", "m2"]).get());
  await assertSucceeds(db.collection("meals").where("planId", "==", "p1").orderBy("name").limit(30).get());
  await assertSucceeds(db.collection("meals").where("isPublic", "==", true).get());
});
test("signed-out meal read denied", () => assertFails(as(null).doc("meals/m1").get()));
test("createMeal in own plan", () => assertSucceeds(as("alice").collection("meals").add(mealMap())));
test("createMeal in foreign plan denied", () => assertFails(as("alice").collection("meals").add(mealMap({ planId: "p2" }))));
test("createMeal isPublic denied", () => assertFails(as("alice").collection("meals").add(mealMap({ isPublic: true }))));
test("updateMeal full map", () => assertSucceeds(as("alice").doc("meals/m1").update(mealMap({ name: "Better" }))));
test("updateMeal on legacy isPublic null", () => assertSucceeds(as("alice").doc("meals/legacyMeal").update(mealMap())));
test("updateMeal moving planId denied", () => assertFails(as("alice").doc("meals/m1").update(mealMap({ planId: "p2" }))));
test("foreign meal update/delete denied", async () => {
  await assertFails(as("alice").doc("meals/m2").update(mealMap({ planId: "p2", name: "x" })));
  await assertFails(as("alice").doc("meals/m2").delete());
});
test("deleteMeal own", () => assertSucceeds(as("alice").doc("meals/m1").delete()));

// --- shopping lists ---------------------------------------------------------------
test("shopping list + groceries for member", async () => {
  const db = as("alice");
  await assertSucceeds(db.collection("shoppinglists").where("planId", "==", "p1").limit(1).get());
  await assertSucceeds(db.collection("shoppinglists/sl1/groceries").orderBy("name").get());
  await assertSucceeds(db.collection("shoppinglists/sl1/groceries").where("bought", "==", true).get());
  await assertSucceeds(db.doc("shoppinglists/sl1/groceries/g1").update({ bought: true, lastBoughtEdited: 5 }));
  await assertSucceeds(db.doc("shoppinglists/sl1/groceries/g1").delete());
});
test("groceries for non-member denied", () => assertFails(as("bob").collection("shoppinglists/sl1/groceries").get()));
test("shopping list doc update denied", () => assertFails(as("alice").doc("shoppinglists/sl1").update({ planId: "p2" })));

// --- users ------------------------------------------------------------------------
test("createUserWithId", () => assertSucceeds(as("bob").doc("users/bob").set(userMap({ oldPlans: [] }))));
test("create as admin denied", () => assertFails(as("bob").doc("users/bob").set(userMap({ role: "admin" }))));
test("create with gifted premium denied", () =>
  assertFails(as("bob").doc("users/bob").set(userMap({ isPremiumGifted: true, premiumGiftedMonths: 12 }))));
test("read other user denied", () => assertFails(as("bob").doc("users/alice").get()));
test("write other user denied", () => assertFails(as("bob").doc("users/alice").update({ isPremium: true })));
test("own updates: oldPlans, isPremium, aiConsentAt", async () => {
  const db = as("alice");
  await assertSucceeds(db.doc("users/alice").update({ oldPlans: ["p1", "p9"] }));
  await assertSucceeds(db.doc("users/alice").update({ isPremium: true }));
  await assertSucceeds(db.doc("users/alice").update({ aiConsentAt: 123 }));
});
test("self-promote to admin denied", () => assertFails(as("alice").doc("users/alice").update({ role: "admin" })));
test("self-gift premium denied", () =>
  assertFails(as("alice").doc("users/alice").update({ isPremiumGifted: true, premiumGiftedAt: 9, premiumGiftedMonths: 1200 })));
test("setPremiumGiftedMessageShown (full map)", () =>
  assertSucceeds(as("gifted").doc("users/gifted").update(userMap({
    isPremiumGifted: true, premiumGiftedAt: 5, premiumGiftedMonths: 1200, premiumGiftedMessageShown: true,
  }))));
test("resetPremiumGifted (full map)", () =>
  assertSucceeds(as("gifted").doc("users/gifted").update(userMap({ isPremiumGifted: false, premiumGiftedMonths: 1200 }))));
test("extend gifted months denied", () =>
  assertFails(as("gifted").doc("users/gifted").update({ premiumGiftedMonths: 9999 })));
test("legacy role string normalizes to 'user'", () =>
  assertSucceeds(as("legacyRole").doc("users/legacyRole").update(userMap({ premiumGiftedMessageShown: true }))));
test("deleteUserById own", () => assertSucceeds(as("alice").doc("users/alice").delete()));

// --- misc ----------------------------------------------------------------------------
test("feedback create only", async () => {
  const db = as("alice");
  await assertSucceeds(db.collection("feedbacks").add({ userId: "alice", title: "Hi" }));
  await assertFails(db.collection("feedbacks").get());
});
test("aiUsage: own read only", async () => {
  await assertSucceeds(as("alice").doc("aiUsage/alice").get());
  await assertFails(as("bob").doc("aiUsage/alice").get());
  await assertFails(as("alice").doc("aiUsage/alice").set({ textUsed: 0 }));
});
test("library_meals read-only", async () => {
  await assertSucceeds(as("alice").collection("library_meals").get());
  await assertFails(as("alice").doc("library_meals/x").set({}));
});
test("versions public read", () => assertSucceeds(as(null).doc("versions/v").get()));
test("API-only collections denied", async () => {
  const db = as("alice");
  await assertFails(db.doc("mcpTokens/victim").set({ hash: "mine", createdAt: 1 }));
  await assertFails(db.doc("mcpTokens/alice").get());
  for (const c of ["generatedMeals", "instagramPosts", "issues", "changes", "missingGroceries"]) {
    await assertFails(db.doc(`${c}/x`).set({ a: 1 }));
    await assertFails(db.collection(c).get());
  }
});

// --- foodly-info (admin) ---------------------------------------------------------------
test("admin: feedback, logs, missing groceries", async () => {
  const db = as("admin");
  await assertSucceeds(db.collection("feedbacks").orderBy("date", "desc").get());
  await assertSucceeds(db.collection("feedbacks").where("userId", "==", "alice").get());
  await assertSucceeds(db.doc("feedbacks/f1").delete());
  await assertSucceeds(db.collection("logs").get());
  await assertSucceeds(db.doc("logs/l1").delete());
  await assertSucceeds(db.collection("missingGroceries").where("count", ">=", 10).limit(50).get());
  await assertSucceeds(db.doc("missingGroceries/mg1").delete());
  await assertFails(db.doc("missingGroceries/x").set({ count: 1 }));
});
test("admin: changes CRUD", async () => {
  const db = as("admin");
  await assertSucceeds(db.collection("changes").get());
  await assertSucceeds(db.collection("changes").where("version", "==", "1.0.0").get());
  await assertSucceeds(db.doc("changes/c2").set({ version: "1.0.1", text: "y" }));
  await assertSucceeds(db.doc("changes/c1").delete());
});
test("admin: read user + giftPremium", async () => {
  const db = as("admin");
  await assertSucceeds(db.doc("users/alice").get());
  await assertSucceeds(db.doc("users/alice").update({
    isPremiumGifted: true, premiumGiftedMessageShown: false, premiumGiftedAt: 9, premiumGiftedMonths: 12,
  }));
});
test("admin: other user fields denied", async () => {
  await assertFails(as("admin").doc("users/alice").update({ role: "admin" }));
  await assertFails(as("admin").doc("users/alice").update({ isPremium: true }));
  await assertFails(as("admin").doc("users/alice").delete());
});
test("non-admin: admin collections denied", async () => {
  const db = as("alice");
  await assertFails(db.doc("feedbacks/f1").delete());
  await assertFails(db.collection("logs").get());
  await assertFails(db.doc("changes/c1").get());
  await assertFails(as(null).collection("changes").get());
});
