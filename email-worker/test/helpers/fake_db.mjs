/**
 * Minimal in-memory Firestore fake for the email worker tasks. Supports the
 * subset the tasks use: collection().where().limit().startAfter().get(),
 * collection().doc(), and batch()/set/commit.
 */
export function makeFakeDb(users) {
  const writes = [];
  let committed = false;

  const makeQuery = () => {
    const q = {
      _preds: [],
      _limit: Infinity,
      _after: null,
      where(field, op, value) {
        this._preds.push([field, op, value]);
        return this;
      },
      limit(n) {
        this._limit = n;
        return this;
      },
      startAfter(doc) {
        this._after = doc.id;
        return this;
      },
      async get() {
        let docs = [...users];
        for (const [field, op, value] of this._preds) {
          docs = docs.filter((d) => {
            const dv = d.data[field];
            if (dv == null) return false;
            if (dv instanceof Date && value instanceof Date) {
              return op === ">=" ? dv >= value : dv <= value;
            }
            return true;
          });
        }
        if (this._after) {
          docs = docs.filter((d) => d.id > this._after);
        }
        docs = docs.slice(0, this._limit);
        return {
          empty: docs.length === 0,
          docs: docs.map((d) => ({ id: d.id, data: () => ({ ...d.data }) })),
        };
      },
    };
    return q;
  };

  const db = {
    collection(name) {
      return {
        doc(id) {
          return { id, path: `${name}/${id}` };
        },
        where(field, op, value) {
          return makeQuery().where(field, op, value);
        },
        limit(n) {
          return makeQuery().limit(n);
        },
      };
    },
    batch() {
      const b = {
        set(ref, data, opts) {
          writes.push({ op: "set", path: ref.path, data, opts });
          return b;
        },
        async commit() {
          committed = true;
        },
      };
      return b;
    },
  };

  return {
    db,
    writes,
    get committed() {
      return committed;
    },
  };
}

/** Fake Firebase Auth for the grace task (getUser by uid). */
export function makeFakeAuth(verifiedByUid) {
  return {
    getUser(uid) {
      if (!(uid in verifiedByUid)) {
        return Promise.reject(new Error("user not found"));
      }
      return Promise.resolve({ uid, emailVerified: verifiedByUid[uid] });
    },
  };
}

/** Collects sends; throws per-recipient when asked. */
export function makeSender({ failFor = new Set() } = {}) {
  const sent = [];
  return {
    sent,
    async send({ to, subject, html }) {
      if (failFor.has(to)) {
        throw new Error(`send failed for ${to}`);
      }
      sent.push({ to, subject, html });
    },
  };
}
