# 🍃 MongoDB Cheatsheet

> A concise collection of MongoDB shell (`mongosh`) commands, query idioms, and best practices for the document database.

---

## 💻 Connect (mongosh)

```bash
mongosh                                   # local default
mongosh "mongodb://user:pass@host:27017/mydb"
mongosh "mongodb+srv://cluster.mongodb.net/mydb" --username admin
```

### Shell basics
```js
show dbs
use mydb                 // switch/create db
show collections
db.dropDatabase()
db.users.drop()
```

---

## 🔍 Querying (find)

```js
db.users.find()                                   // all
db.users.find({ age: { $gte: 18 } })              // filter
db.users.findOne({ email: "a@x.com" })
db.users.find({ country: "FR" }, { name: 1, _id: 0 })   // projection
db.users.find().sort({ age: -1 }).limit(10).skip(20)    // sort + paginate
db.users.countDocuments({ active: true })
```

### Query operators
| Operator | Meaning              | Operator | Meaning            |
|----------|----------------------|----------|--------------------|
| `$eq`    | equal                | `$ne`    | not equal          |
| `$gt/$gte` | greater (or eq)    | `$lt/$lte` | less (or eq)     |
| `$in`    | in array             | `$nin`   | not in array       |
| `$and/$or/$nor` | logical       | `$not`   | negate             |
| `$exists`| field present        | `$type`  | field type         |
| `$regex` | pattern match        | `$all`   | array contains all |
| `$elemMatch` | array element cond | `$size` | array length      |

```js
db.users.find({ $or: [{ age: { $lt: 18 } }, { vip: true }] })
db.users.find({ tags: { $in: ["admin", "editor"] } })
db.users.find({ name: { $regex: /^A/, $options: "i" } })
```

---

## ✏️ Insert / Update / Delete

```js
db.users.insertOne({ name: "Ana", age: 30 })
db.users.insertMany([{ name: "B" }, { name: "C" }])

db.users.updateOne({ _id: id }, { $set: { active: false } })
db.users.updateMany({ country: "FR" }, { $inc: { visits: 1 } })
db.users.updateOne({ _id: id }, { $push: { tags: "new" } })
db.users.updateOne({ email: "a@x" }, { $set: { name: "Ana" } }, { upsert: true })

db.users.replaceOne({ _id: id }, { name: "New Doc" })
db.users.deleteOne({ _id: id })
db.users.deleteMany({ active: false })
```

### Update operators
`$set`, `$unset`, `$inc`, `$mul`, `$rename`, `$min`, `$max`,
`$push`, `$pull`, `$addToSet`, `$pop` (arrays), `$currentDate`.

---

## 🔗 Aggregation Pipeline

```js
db.orders.aggregate([
  { $match: { status: "paid" } },                       // filter
  { $group: { _id: "$userId", total: { $sum: "$amount" }, n: { $sum: 1 } } },
  { $sort: { total: -1 } },
  { $limit: 10 },
  { $lookup: {                                          // "join"
      from: "users", localField: "_id",
      foreignField: "_id", as: "user" } },
  { $unwind: "$user" },
  { $project: { _id: 0, name: "$user.name", total: 1 } }
])
```

Common stages: `$match`, `$group`, `$project`, `$sort`, `$limit`, `$skip`,
`$lookup`, `$unwind`, `$addFields`, `$facet`, `$count`, `$bucket`.

> 💡 Put `$match` and `$project` **early** to reduce documents flowing through the pipeline.

---

## ⚡ Indexes

```js
db.users.createIndex({ email: 1 }, { unique: true })     // 1 = asc, -1 = desc
db.users.createIndex({ country: 1, age: -1 })            // compound
db.users.createIndex({ location: "2dsphere" })           // geospatial
db.articles.createIndex({ body: "text" })                // full-text
db.users.createIndex({ createdAt: 1 }, { expireAfterSeconds: 3600 })  // TTL
db.users.getIndexes()
db.users.dropIndex("email_1")
```

* Compound index field **order matters** (ESR rule: Equality, Sort, Range).
* Use `.explain("executionStats")` to check index usage.

---

## 🧠 Best Practices

* **Model for your access patterns** — embed related data read together; reference data that grows unbounded or is shared.
* Avoid unbounded array growth in a single document (16MB doc limit).
* Index the fields you filter/sort on; watch write cost of too many indexes.
* Use **projection** to fetch only needed fields.
* Prefer `countDocuments()` over deprecated `count()`.
* Use schema validation (`$jsonSchema`) to enforce structure where needed.
* Use transactions (`session.withTransaction`) only when you truly need multi-doc atomicity.

---

## 🔧 Ops & Introspection

```js
db.stats()
db.users.stats()
db.users.find(...).explain("executionStats")
db.currentOp()
db.serverStatus()
mongodump --uri="mongodb://..." --out=./backup     // shell: backup
mongorestore --uri="mongodb://..." ./backup        // shell: restore
```

---

## ⚠️ Common Gotchas

* `_id` is auto-generated `ObjectId` — immutable once set.
* Documents in a collection can have different shapes (schemaless) — validate at the app or with `$jsonSchema`.
* `find()` returns a cursor — it's lazy; iterate or `.toArray()`.
* Comparing types: MongoDB has a type-ordering; `null`, missing field, and `$exists:false` differ subtly.
* Max BSON document size is **16 MB**; use GridFS for larger blobs.
* Case-sensitive string matches unless you use collation or regex `i`.

---

Crafted with ☕ and a healthy dose of laziness by Anthony Lewandowski.
