
// ======================================================================
// MongoDB Schema for "App Suite" (collections dinamiche + indici)
// ======================================================================

// recipes_raw
db.createCollection("recipes_raw", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["user_id","base_servings","created_at"],
      properties: {
        user_id: { },
        base_servings: { bsonType: "int" },
        raw_text: { bsonType: ["string","null"] },
        url: { bsonType: ["string","null"] },
        images: { bsonType: "array" },
        parsed: { bsonType: "object" },
        variants: { bsonType: "array" },
        schema_version: { bsonType: "int" },
        created_at: { bsonType: "date" }
      }
    }
  }
});
db.recipes_raw.createIndex({ user_id: 1, created_at: -1 });

// ocr_payloads
db.createCollection("ocr_payloads", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["user_id","type","text","created_at"],
      properties: {
        user_id: { },
        type: { enum: ["receipt","event","menu"] },
        image_ref: { bsonType: ["string","null"] },
        text: { bsonType: "string" },
        boxes: { bsonType: "array" },
        confidence: { bsonType: ["double","int","long","decimal","null"] },
        created_at: { bsonType: "date" }
      }
    }
  }
});
db.ocr_payloads.createIndex({ user_id: 1, type: 1, created_at: -1 });

// user_section_templates
db.createCollection("user_section_templates", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["user_id","list_id","sections","version","created_at"],
      properties: {
        user_id: { },
        list_id: { },
        sections: { bsonType: "array" },
        version: { bsonType: "int" },
        created_at: { bsonType: "date" }
      }
    }
  }
});
db.user_section_templates.createIndex({ user_id: 1, list_id: 1 });

// preferences
db.createCollection("preferences", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["user_id","created_at"],
      properties: {
        user_id: { },
        diets: { bsonType: "array" },
        allergens: { bsonType: "array" },
        unit_prefs: { bsonType: "object" },
        store_routes: { bsonType: "object" },
        aliases: { bsonType: "object" },
        created_at: { bsonType: "date" }
      }
    }
  }
});
db.preferences.createIndex({ user_id: 1 }, { unique: true });

// activities (audit / analytics light)
db.createCollection("activities", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["type","created_at"],
      properties: {
        pair_id: { },
        user_id: { },
        type: { bsonType: "string" },
        payload: { bsonType: "object" },
        created_at: { bsonType: "date" },
        ttl: { bsonType: ["int","long","null"] }
      }
    }
  }
});
db.activities.createIndex({ pair_id: 1, created_at: -1 });
db.activities.createIndex({ user_id: 1, created_at: -1 });

// feature_flags (per esperimenti e rollout)
db.createCollection("feature_flags", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["user_id","created_at"],
      properties: {
        user_id: { },
        flags: { bsonType: "object" },
        experiments: { bsonType: "object" },
        created_at: { bsonType: "date" }
      }
    }
  }
});
db.feature_flags.createIndex({ user_id: 1 }, { unique: true });
