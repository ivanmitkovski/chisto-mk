
/**
 * Client
**/

import * as runtime from './runtime/client.js';
import $Types = runtime.Types // general types
import $Public = runtime.Types.Public
import $Utils = runtime.Types.Utils
import $Extensions = runtime.Types.Extensions
import $Result = runtime.Types.Result

export type PrismaPromise<T> = $Public.PrismaPromise<T>


/**
 * Model User
 * 
 */
export type User = $Result.DefaultSelection<Prisma.$UserPayload>
/**
 * Model UserSession
 * 
 */
export type UserSession = $Result.DefaultSelection<Prisma.$UserSessionPayload>
/**
 * Model PhoneOtp
 * 
 */
export type PhoneOtp = $Result.DefaultSelection<Prisma.$PhoneOtpPayload>
/**
 * Model LoginFailure
 * 
 */
export type LoginFailure = $Result.DefaultSelection<Prisma.$LoginFailurePayload>
/**
 * Model AdminNotification
 * 
 */
export type AdminNotification = $Result.DefaultSelection<Prisma.$AdminNotificationPayload>
/**
 * Model PointTransaction
 * 
 */
export type PointTransaction = $Result.DefaultSelection<Prisma.$PointTransactionPayload>
/**
 * Model Site
 * 
 */
export type Site = $Result.DefaultSelection<Prisma.$SitePayload>
/**
 * Model Report
 * 
 */
export type Report = $Result.DefaultSelection<Prisma.$ReportPayload>
/**
 * Model ReportCoReporter
 * 
 */
export type ReportCoReporter = $Result.DefaultSelection<Prisma.$ReportCoReporterPayload>
/**
 * Model CleanupEvent
 * 
 */
export type CleanupEvent = $Result.DefaultSelection<Prisma.$CleanupEventPayload>

/**
 * Enums
 */
export namespace $Enums {
  export const Role: {
  USER: 'USER',
  ADMIN: 'ADMIN'
};

export type Role = (typeof Role)[keyof typeof Role]


export const UserStatus: {
  ACTIVE: 'ACTIVE',
  SUSPENDED: 'SUSPENDED',
  DELETED: 'DELETED'
};

export type UserStatus = (typeof UserStatus)[keyof typeof UserStatus]


export const AdminNotificationTone: {
  success: 'success',
  warning: 'warning',
  info: 'info',
  neutral: 'neutral'
};

export type AdminNotificationTone = (typeof AdminNotificationTone)[keyof typeof AdminNotificationTone]


export const AdminNotificationCategory: {
  reports: 'reports',
  system: 'system',
  analytics: 'analytics'
};

export type AdminNotificationCategory = (typeof AdminNotificationCategory)[keyof typeof AdminNotificationCategory]


export const SiteStatus: {
  REPORTED: 'REPORTED',
  VERIFIED: 'VERIFIED',
  CLEANUP_SCHEDULED: 'CLEANUP_SCHEDULED',
  IN_PROGRESS: 'IN_PROGRESS',
  CLEANED: 'CLEANED',
  DISPUTED: 'DISPUTED'
};

export type SiteStatus = (typeof SiteStatus)[keyof typeof SiteStatus]


export const ReportStatus: {
  NEW: 'NEW',
  IN_REVIEW: 'IN_REVIEW',
  APPROVED: 'APPROVED',
  DELETED: 'DELETED'
};

export type ReportStatus = (typeof ReportStatus)[keyof typeof ReportStatus]

}

export type Role = $Enums.Role

export const Role: typeof $Enums.Role

export type UserStatus = $Enums.UserStatus

export const UserStatus: typeof $Enums.UserStatus

export type AdminNotificationTone = $Enums.AdminNotificationTone

export const AdminNotificationTone: typeof $Enums.AdminNotificationTone

export type AdminNotificationCategory = $Enums.AdminNotificationCategory

export const AdminNotificationCategory: typeof $Enums.AdminNotificationCategory

export type SiteStatus = $Enums.SiteStatus

export const SiteStatus: typeof $Enums.SiteStatus

export type ReportStatus = $Enums.ReportStatus

export const ReportStatus: typeof $Enums.ReportStatus

/**
 * ##  Prisma Client ʲˢ
 *
 * Type-safe database client for TypeScript & Node.js
 * @example
 * ```
 * const prisma = new PrismaClient({
 *   adapter: new PrismaPg({ connectionString: process.env.DATABASE_URL })
 * })
 * // Fetch zero or more Users
 * const users = await prisma.user.findMany()
 * ```
 *
 *
 * Read more in our [docs](https://pris.ly/d/client).
 */
export class PrismaClient<
  ClientOptions extends Prisma.PrismaClientOptions = Prisma.PrismaClientOptions,
  const U = 'log' extends keyof ClientOptions ? ClientOptions['log'] extends Array<Prisma.LogLevel | Prisma.LogDefinition> ? Prisma.GetEvents<ClientOptions['log']> : never : never,
  ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs
> {
  [K: symbol]: { types: Prisma.TypeMap<ExtArgs>['other'] }

    /**
   * ##  Prisma Client ʲˢ
   *
   * Type-safe database client for TypeScript & Node.js
   * @example
   * ```
   * const prisma = new PrismaClient({
   *   adapter: new PrismaPg({ connectionString: process.env.DATABASE_URL })
   * })
   * // Fetch zero or more Users
   * const users = await prisma.user.findMany()
   * ```
   *
   *
   * Read more in our [docs](https://pris.ly/d/client).
   */

  constructor(optionsArg ?: Prisma.Subset<ClientOptions, Prisma.PrismaClientOptions>);
  $on<V extends U>(eventType: V, callback: (event: V extends 'query' ? Prisma.QueryEvent : Prisma.LogEvent) => void): PrismaClient;

  /**
   * Connect with the database
   */
  $connect(): $Utils.JsPromise<void>;

  /**
   * Disconnect from the database
   */
  $disconnect(): $Utils.JsPromise<void>;

/**
   * Executes a prepared raw query and returns the number of affected rows.
   * @example
   * ```
   * const result = await prisma.$executeRaw`UPDATE User SET cool = ${true} WHERE email = ${'user@email.com'};`
   * ```
   *
   * Read more in our [docs](https://pris.ly/d/raw-queries).
   */
  $executeRaw<T = unknown>(query: TemplateStringsArray | Prisma.Sql, ...values: any[]): Prisma.PrismaPromise<number>;

  /**
   * Executes a raw query and returns the number of affected rows.
   * Susceptible to SQL injections, see documentation.
   * @example
   * ```
   * const result = await prisma.$executeRawUnsafe('UPDATE User SET cool = $1 WHERE email = $2 ;', true, 'user@email.com')
   * ```
   *
   * Read more in our [docs](https://pris.ly/d/raw-queries).
   */
  $executeRawUnsafe<T = unknown>(query: string, ...values: any[]): Prisma.PrismaPromise<number>;

  /**
   * Performs a prepared raw query and returns the `SELECT` data.
   * @example
   * ```
   * const result = await prisma.$queryRaw`SELECT * FROM User WHERE id = ${1} OR email = ${'user@email.com'};`
   * ```
   *
   * Read more in our [docs](https://pris.ly/d/raw-queries).
   */
  $queryRaw<T = unknown>(query: TemplateStringsArray | Prisma.Sql, ...values: any[]): Prisma.PrismaPromise<T>;

  /**
   * Performs a raw query and returns the `SELECT` data.
   * Susceptible to SQL injections, see documentation.
   * @example
   * ```
   * const result = await prisma.$queryRawUnsafe('SELECT * FROM User WHERE id = $1 OR email = $2;', 1, 'user@email.com')
   * ```
   *
   * Read more in our [docs](https://pris.ly/d/raw-queries).
   */
  $queryRawUnsafe<T = unknown>(query: string, ...values: any[]): Prisma.PrismaPromise<T>;


  /**
   * Allows the running of a sequence of read/write operations that are guaranteed to either succeed or fail as a whole.
   * @example
   * ```
   * const [george, bob, alice] = await prisma.$transaction([
   *   prisma.user.create({ data: { name: 'George' } }),
   *   prisma.user.create({ data: { name: 'Bob' } }),
   *   prisma.user.create({ data: { name: 'Alice' } }),
   * ])
   * ```
   * 
   * Read more in our [docs](https://www.prisma.io/docs/orm/prisma-client/queries/transactions).
   */
  $transaction<P extends Prisma.PrismaPromise<any>[]>(arg: [...P], options?: { isolationLevel?: Prisma.TransactionIsolationLevel }): $Utils.JsPromise<runtime.Types.Utils.UnwrapTuple<P>>

  $transaction<R>(fn: (prisma: Omit<PrismaClient, runtime.ITXClientDenyList>) => $Utils.JsPromise<R>, options?: { maxWait?: number, timeout?: number, isolationLevel?: Prisma.TransactionIsolationLevel }): $Utils.JsPromise<R>

  $extends: $Extensions.ExtendsHook<"extends", Prisma.TypeMapCb<ClientOptions>, ExtArgs, $Utils.Call<Prisma.TypeMapCb<ClientOptions>, {
    extArgs: ExtArgs
  }>>

      /**
   * `prisma.user`: Exposes CRUD operations for the **User** model.
    * Example usage:
    * ```ts
    * // Fetch zero or more Users
    * const users = await prisma.user.findMany()
    * ```
    */
  get user(): Prisma.UserDelegate<ExtArgs, ClientOptions>;

  /**
   * `prisma.userSession`: Exposes CRUD operations for the **UserSession** model.
    * Example usage:
    * ```ts
    * // Fetch zero or more UserSessions
    * const userSessions = await prisma.userSession.findMany()
    * ```
    */
  get userSession(): Prisma.UserSessionDelegate<ExtArgs, ClientOptions>;

  /**
   * `prisma.phoneOtp`: Exposes CRUD operations for the **PhoneOtp** model.
    * Example usage:
    * ```ts
    * // Fetch zero or more PhoneOtps
    * const phoneOtps = await prisma.phoneOtp.findMany()
    * ```
    */
  get phoneOtp(): Prisma.PhoneOtpDelegate<ExtArgs, ClientOptions>;

  /**
   * `prisma.loginFailure`: Exposes CRUD operations for the **LoginFailure** model.
    * Example usage:
    * ```ts
    * // Fetch zero or more LoginFailures
    * const loginFailures = await prisma.loginFailure.findMany()
    * ```
    */
  get loginFailure(): Prisma.LoginFailureDelegate<ExtArgs, ClientOptions>;

  /**
   * `prisma.adminNotification`: Exposes CRUD operations for the **AdminNotification** model.
    * Example usage:
    * ```ts
    * // Fetch zero or more AdminNotifications
    * const adminNotifications = await prisma.adminNotification.findMany()
    * ```
    */
  get adminNotification(): Prisma.AdminNotificationDelegate<ExtArgs, ClientOptions>;

  /**
   * `prisma.pointTransaction`: Exposes CRUD operations for the **PointTransaction** model.
    * Example usage:
    * ```ts
    * // Fetch zero or more PointTransactions
    * const pointTransactions = await prisma.pointTransaction.findMany()
    * ```
    */
  get pointTransaction(): Prisma.PointTransactionDelegate<ExtArgs, ClientOptions>;

  /**
   * `prisma.site`: Exposes CRUD operations for the **Site** model.
    * Example usage:
    * ```ts
    * // Fetch zero or more Sites
    * const sites = await prisma.site.findMany()
    * ```
    */
  get site(): Prisma.SiteDelegate<ExtArgs, ClientOptions>;

  /**
   * `prisma.report`: Exposes CRUD operations for the **Report** model.
    * Example usage:
    * ```ts
    * // Fetch zero or more Reports
    * const reports = await prisma.report.findMany()
    * ```
    */
  get report(): Prisma.ReportDelegate<ExtArgs, ClientOptions>;

  /**
   * `prisma.reportCoReporter`: Exposes CRUD operations for the **ReportCoReporter** model.
    * Example usage:
    * ```ts
    * // Fetch zero or more ReportCoReporters
    * const reportCoReporters = await prisma.reportCoReporter.findMany()
    * ```
    */
  get reportCoReporter(): Prisma.ReportCoReporterDelegate<ExtArgs, ClientOptions>;

  /**
   * `prisma.cleanupEvent`: Exposes CRUD operations for the **CleanupEvent** model.
    * Example usage:
    * ```ts
    * // Fetch zero or more CleanupEvents
    * const cleanupEvents = await prisma.cleanupEvent.findMany()
    * ```
    */
  get cleanupEvent(): Prisma.CleanupEventDelegate<ExtArgs, ClientOptions>;
}

export namespace Prisma {
  export import DMMF = runtime.DMMF

  export type PrismaPromise<T> = $Public.PrismaPromise<T>

  /**
   * Validator
   */
  export import validator = runtime.Public.validator

  /**
   * Prisma Errors
   */
  export import PrismaClientKnownRequestError = runtime.PrismaClientKnownRequestError
  export import PrismaClientUnknownRequestError = runtime.PrismaClientUnknownRequestError
  export import PrismaClientRustPanicError = runtime.PrismaClientRustPanicError
  export import PrismaClientInitializationError = runtime.PrismaClientInitializationError
  export import PrismaClientValidationError = runtime.PrismaClientValidationError

  /**
   * Re-export of sql-template-tag
   */
  export import sql = runtime.sqltag
  export import empty = runtime.empty
  export import join = runtime.join
  export import raw = runtime.raw
  export import Sql = runtime.Sql



  /**
   * Decimal.js
   */
  export import Decimal = runtime.Decimal

  export type DecimalJsLike = runtime.DecimalJsLike

  /**
  * Extensions
  */
  export import Extension = $Extensions.UserArgs
  export import getExtensionContext = runtime.Extensions.getExtensionContext
  export import Args = $Public.Args
  export import Payload = $Public.Payload
  export import Result = $Public.Result
  export import Exact = $Public.Exact

  /**
   * Prisma Client JS version: 7.5.0
   * Query Engine version: 280c870be64f457428992c43c1f6d557fab6e29e
   */
  export type PrismaVersion = {
    client: string
    engine: string
  }

  export const prismaVersion: PrismaVersion

  /**
   * Utility Types
   */


  export import Bytes = runtime.Bytes
  export import JsonObject = runtime.JsonObject
  export import JsonArray = runtime.JsonArray
  export import JsonValue = runtime.JsonValue
  export import InputJsonObject = runtime.InputJsonObject
  export import InputJsonArray = runtime.InputJsonArray
  export import InputJsonValue = runtime.InputJsonValue

  /**
   * Types of the values used to represent different kinds of `null` values when working with JSON fields.
   *
   * @see https://www.prisma.io/docs/concepts/components/prisma-client/working-with-fields/working-with-json-fields#filtering-on-a-json-field
   */
  namespace NullTypes {
    /**
    * Type of `Prisma.DbNull`.
    *
    * You cannot use other instances of this class. Please use the `Prisma.DbNull` value.
    *
    * @see https://www.prisma.io/docs/concepts/components/prisma-client/working-with-fields/working-with-json-fields#filtering-on-a-json-field
    */
    class DbNull {
      private DbNull: never
      private constructor()
    }

    /**
    * Type of `Prisma.JsonNull`.
    *
    * You cannot use other instances of this class. Please use the `Prisma.JsonNull` value.
    *
    * @see https://www.prisma.io/docs/concepts/components/prisma-client/working-with-fields/working-with-json-fields#filtering-on-a-json-field
    */
    class JsonNull {
      private JsonNull: never
      private constructor()
    }

    /**
    * Type of `Prisma.AnyNull`.
    *
    * You cannot use other instances of this class. Please use the `Prisma.AnyNull` value.
    *
    * @see https://www.prisma.io/docs/concepts/components/prisma-client/working-with-fields/working-with-json-fields#filtering-on-a-json-field
    */
    class AnyNull {
      private AnyNull: never
      private constructor()
    }
  }

  /**
   * Helper for filtering JSON entries that have `null` on the database (empty on the db)
   *
   * @see https://www.prisma.io/docs/concepts/components/prisma-client/working-with-fields/working-with-json-fields#filtering-on-a-json-field
   */
  export const DbNull: NullTypes.DbNull

  /**
   * Helper for filtering JSON entries that have JSON `null` values (not empty on the db)
   *
   * @see https://www.prisma.io/docs/concepts/components/prisma-client/working-with-fields/working-with-json-fields#filtering-on-a-json-field
   */
  export const JsonNull: NullTypes.JsonNull

  /**
   * Helper for filtering JSON entries that are `Prisma.DbNull` or `Prisma.JsonNull`
   *
   * @see https://www.prisma.io/docs/concepts/components/prisma-client/working-with-fields/working-with-json-fields#filtering-on-a-json-field
   */
  export const AnyNull: NullTypes.AnyNull

  type SelectAndInclude = {
    select: any
    include: any
  }

  type SelectAndOmit = {
    select: any
    omit: any
  }

  /**
   * Get the type of the value, that the Promise holds.
   */
  export type PromiseType<T extends PromiseLike<any>> = T extends PromiseLike<infer U> ? U : T;

  /**
   * Get the return type of a function which returns a Promise.
   */
  export type PromiseReturnType<T extends (...args: any) => $Utils.JsPromise<any>> = PromiseType<ReturnType<T>>

  /**
   * From T, pick a set of properties whose keys are in the union K
   */
  type Prisma__Pick<T, K extends keyof T> = {
      [P in K]: T[P];
  };


  export type Enumerable<T> = T | Array<T>;

  export type RequiredKeys<T> = {
    [K in keyof T]-?: {} extends Prisma__Pick<T, K> ? never : K
  }[keyof T]

  export type TruthyKeys<T> = keyof {
    [K in keyof T as T[K] extends false | undefined | null ? never : K]: K
  }

  export type TrueKeys<T> = TruthyKeys<Prisma__Pick<T, RequiredKeys<T>>>

  /**
   * Subset
   * @desc From `T` pick properties that exist in `U`. Simple version of Intersection
   */
  export type Subset<T, U> = {
    [key in keyof T]: key extends keyof U ? T[key] : never;
  };

  /**
   * SelectSubset
   * @desc From `T` pick properties that exist in `U`. Simple version of Intersection.
   * Additionally, it validates, if both select and include are present. If the case, it errors.
   */
  export type SelectSubset<T, U> = {
    [key in keyof T]: key extends keyof U ? T[key] : never
  } &
    (T extends SelectAndInclude
      ? 'Please either choose `select` or `include`.'
      : T extends SelectAndOmit
        ? 'Please either choose `select` or `omit`.'
        : {})

  /**
   * Subset + Intersection
   * @desc From `T` pick properties that exist in `U` and intersect `K`
   */
  export type SubsetIntersection<T, U, K> = {
    [key in keyof T]: key extends keyof U ? T[key] : never
  } &
    K

  type Without<T, U> = { [P in Exclude<keyof T, keyof U>]?: never };

  /**
   * XOR is needed to have a real mutually exclusive union type
   * https://stackoverflow.com/questions/42123407/does-typescript-support-mutually-exclusive-types
   */
  type XOR<T, U> =
    T extends object ?
    U extends object ?
      (Without<T, U> & U) | (Without<U, T> & T)
    : U : T


  /**
   * Is T a Record?
   */
  type IsObject<T extends any> = T extends Array<any>
  ? False
  : T extends Date
  ? False
  : T extends Uint8Array
  ? False
  : T extends BigInt
  ? False
  : T extends object
  ? True
  : False


  /**
   * If it's T[], return T
   */
  export type UnEnumerate<T extends unknown> = T extends Array<infer U> ? U : T

  /**
   * From ts-toolbelt
   */

  type __Either<O extends object, K extends Key> = Omit<O, K> &
    {
      // Merge all but K
      [P in K]: Prisma__Pick<O, P & keyof O> // With K possibilities
    }[K]

  type EitherStrict<O extends object, K extends Key> = Strict<__Either<O, K>>

  type EitherLoose<O extends object, K extends Key> = ComputeRaw<__Either<O, K>>

  type _Either<
    O extends object,
    K extends Key,
    strict extends Boolean
  > = {
    1: EitherStrict<O, K>
    0: EitherLoose<O, K>
  }[strict]

  type Either<
    O extends object,
    K extends Key,
    strict extends Boolean = 1
  > = O extends unknown ? _Either<O, K, strict> : never

  export type Union = any

  type PatchUndefined<O extends object, O1 extends object> = {
    [K in keyof O]: O[K] extends undefined ? At<O1, K> : O[K]
  } & {}

  /** Helper Types for "Merge" **/
  export type IntersectOf<U extends Union> = (
    U extends unknown ? (k: U) => void : never
  ) extends (k: infer I) => void
    ? I
    : never

  export type Overwrite<O extends object, O1 extends object> = {
      [K in keyof O]: K extends keyof O1 ? O1[K] : O[K];
  } & {};

  type _Merge<U extends object> = IntersectOf<Overwrite<U, {
      [K in keyof U]-?: At<U, K>;
  }>>;

  type Key = string | number | symbol;
  type AtBasic<O extends object, K extends Key> = K extends keyof O ? O[K] : never;
  type AtStrict<O extends object, K extends Key> = O[K & keyof O];
  type AtLoose<O extends object, K extends Key> = O extends unknown ? AtStrict<O, K> : never;
  export type At<O extends object, K extends Key, strict extends Boolean = 1> = {
      1: AtStrict<O, K>;
      0: AtLoose<O, K>;
  }[strict];

  export type ComputeRaw<A extends any> = A extends Function ? A : {
    [K in keyof A]: A[K];
  } & {};

  export type OptionalFlat<O> = {
    [K in keyof O]?: O[K];
  } & {};

  type _Record<K extends keyof any, T> = {
    [P in K]: T;
  };

  // cause typescript not to expand types and preserve names
  type NoExpand<T> = T extends unknown ? T : never;

  // this type assumes the passed object is entirely optional
  type AtLeast<O extends object, K extends string> = NoExpand<
    O extends unknown
    ? | (K extends keyof O ? { [P in K]: O[P] } & O : O)
      | {[P in keyof O as P extends K ? P : never]-?: O[P]} & O
    : never>;

  type _Strict<U, _U = U> = U extends unknown ? U & OptionalFlat<_Record<Exclude<Keys<_U>, keyof U>, never>> : never;

  export type Strict<U extends object> = ComputeRaw<_Strict<U>>;
  /** End Helper Types for "Merge" **/

  export type Merge<U extends object> = ComputeRaw<_Merge<Strict<U>>>;

  /**
  A [[Boolean]]
  */
  export type Boolean = True | False

  // /**
  // 1
  // */
  export type True = 1

  /**
  0
  */
  export type False = 0

  export type Not<B extends Boolean> = {
    0: 1
    1: 0
  }[B]

  export type Extends<A1 extends any, A2 extends any> = [A1] extends [never]
    ? 0 // anything `never` is false
    : A1 extends A2
    ? 1
    : 0

  export type Has<U extends Union, U1 extends Union> = Not<
    Extends<Exclude<U1, U>, U1>
  >

  export type Or<B1 extends Boolean, B2 extends Boolean> = {
    0: {
      0: 0
      1: 1
    }
    1: {
      0: 1
      1: 1
    }
  }[B1][B2]

  export type Keys<U extends Union> = U extends unknown ? keyof U : never

  type Cast<A, B> = A extends B ? A : B;

  export const type: unique symbol;



  /**
   * Used by group by
   */

  export type GetScalarType<T, O> = O extends object ? {
    [P in keyof T]: P extends keyof O
      ? O[P]
      : never
  } : never

  type FieldPaths<
    T,
    U = Omit<T, '_avg' | '_sum' | '_count' | '_min' | '_max'>
  > = IsObject<T> extends True ? U : T

  type GetHavingFields<T> = {
    [K in keyof T]: Or<
      Or<Extends<'OR', K>, Extends<'AND', K>>,
      Extends<'NOT', K>
    > extends True
      ? // infer is only needed to not hit TS limit
        // based on the brilliant idea of Pierre-Antoine Mills
        // https://github.com/microsoft/TypeScript/issues/30188#issuecomment-478938437
        T[K] extends infer TK
        ? GetHavingFields<UnEnumerate<TK> extends object ? Merge<UnEnumerate<TK>> : never>
        : never
      : {} extends FieldPaths<T[K]>
      ? never
      : K
  }[keyof T]

  /**
   * Convert tuple to union
   */
  type _TupleToUnion<T> = T extends (infer E)[] ? E : never
  type TupleToUnion<K extends readonly any[]> = _TupleToUnion<K>
  type MaybeTupleToUnion<T> = T extends any[] ? TupleToUnion<T> : T

  /**
   * Like `Pick`, but additionally can also accept an array of keys
   */
  type PickEnumerable<T, K extends Enumerable<keyof T> | keyof T> = Prisma__Pick<T, MaybeTupleToUnion<K>>

  /**
   * Exclude all keys with underscores
   */
  type ExcludeUnderscoreKeys<T extends string> = T extends `_${string}` ? never : T


  export type FieldRef<Model, FieldType> = runtime.FieldRef<Model, FieldType>

  type FieldRefInputType<Model, FieldType> = Model extends never ? never : FieldRef<Model, FieldType>


  export const ModelName: {
    User: 'User',
    UserSession: 'UserSession',
    PhoneOtp: 'PhoneOtp',
    LoginFailure: 'LoginFailure',
    AdminNotification: 'AdminNotification',
    PointTransaction: 'PointTransaction',
    Site: 'Site',
    Report: 'Report',
    ReportCoReporter: 'ReportCoReporter',
    CleanupEvent: 'CleanupEvent'
  };

  export type ModelName = (typeof ModelName)[keyof typeof ModelName]



  interface TypeMapCb<ClientOptions = {}> extends $Utils.Fn<{extArgs: $Extensions.InternalArgs }, $Utils.Record<string, any>> {
    returns: Prisma.TypeMap<this['params']['extArgs'], ClientOptions extends { omit: infer OmitOptions } ? OmitOptions : {}>
  }

  export type TypeMap<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs, GlobalOmitOptions = {}> = {
    globalOmitOptions: {
      omit: GlobalOmitOptions
    }
    meta: {
      modelProps: "user" | "userSession" | "phoneOtp" | "loginFailure" | "adminNotification" | "pointTransaction" | "site" | "report" | "reportCoReporter" | "cleanupEvent"
      txIsolationLevel: Prisma.TransactionIsolationLevel
    }
    model: {
      User: {
        payload: Prisma.$UserPayload<ExtArgs>
        fields: Prisma.UserFieldRefs
        operations: {
          findUnique: {
            args: Prisma.UserFindUniqueArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$UserPayload> | null
          }
          findUniqueOrThrow: {
            args: Prisma.UserFindUniqueOrThrowArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$UserPayload>
          }
          findFirst: {
            args: Prisma.UserFindFirstArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$UserPayload> | null
          }
          findFirstOrThrow: {
            args: Prisma.UserFindFirstOrThrowArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$UserPayload>
          }
          findMany: {
            args: Prisma.UserFindManyArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$UserPayload>[]
          }
          create: {
            args: Prisma.UserCreateArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$UserPayload>
          }
          createMany: {
            args: Prisma.UserCreateManyArgs<ExtArgs>
            result: BatchPayload
          }
          createManyAndReturn: {
            args: Prisma.UserCreateManyAndReturnArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$UserPayload>[]
          }
          delete: {
            args: Prisma.UserDeleteArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$UserPayload>
          }
          update: {
            args: Prisma.UserUpdateArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$UserPayload>
          }
          deleteMany: {
            args: Prisma.UserDeleteManyArgs<ExtArgs>
            result: BatchPayload
          }
          updateMany: {
            args: Prisma.UserUpdateManyArgs<ExtArgs>
            result: BatchPayload
          }
          updateManyAndReturn: {
            args: Prisma.UserUpdateManyAndReturnArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$UserPayload>[]
          }
          upsert: {
            args: Prisma.UserUpsertArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$UserPayload>
          }
          aggregate: {
            args: Prisma.UserAggregateArgs<ExtArgs>
            result: $Utils.Optional<AggregateUser>
          }
          groupBy: {
            args: Prisma.UserGroupByArgs<ExtArgs>
            result: $Utils.Optional<UserGroupByOutputType>[]
          }
          count: {
            args: Prisma.UserCountArgs<ExtArgs>
            result: $Utils.Optional<UserCountAggregateOutputType> | number
          }
        }
      }
      UserSession: {
        payload: Prisma.$UserSessionPayload<ExtArgs>
        fields: Prisma.UserSessionFieldRefs
        operations: {
          findUnique: {
            args: Prisma.UserSessionFindUniqueArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$UserSessionPayload> | null
          }
          findUniqueOrThrow: {
            args: Prisma.UserSessionFindUniqueOrThrowArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$UserSessionPayload>
          }
          findFirst: {
            args: Prisma.UserSessionFindFirstArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$UserSessionPayload> | null
          }
          findFirstOrThrow: {
            args: Prisma.UserSessionFindFirstOrThrowArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$UserSessionPayload>
          }
          findMany: {
            args: Prisma.UserSessionFindManyArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$UserSessionPayload>[]
          }
          create: {
            args: Prisma.UserSessionCreateArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$UserSessionPayload>
          }
          createMany: {
            args: Prisma.UserSessionCreateManyArgs<ExtArgs>
            result: BatchPayload
          }
          createManyAndReturn: {
            args: Prisma.UserSessionCreateManyAndReturnArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$UserSessionPayload>[]
          }
          delete: {
            args: Prisma.UserSessionDeleteArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$UserSessionPayload>
          }
          update: {
            args: Prisma.UserSessionUpdateArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$UserSessionPayload>
          }
          deleteMany: {
            args: Prisma.UserSessionDeleteManyArgs<ExtArgs>
            result: BatchPayload
          }
          updateMany: {
            args: Prisma.UserSessionUpdateManyArgs<ExtArgs>
            result: BatchPayload
          }
          updateManyAndReturn: {
            args: Prisma.UserSessionUpdateManyAndReturnArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$UserSessionPayload>[]
          }
          upsert: {
            args: Prisma.UserSessionUpsertArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$UserSessionPayload>
          }
          aggregate: {
            args: Prisma.UserSessionAggregateArgs<ExtArgs>
            result: $Utils.Optional<AggregateUserSession>
          }
          groupBy: {
            args: Prisma.UserSessionGroupByArgs<ExtArgs>
            result: $Utils.Optional<UserSessionGroupByOutputType>[]
          }
          count: {
            args: Prisma.UserSessionCountArgs<ExtArgs>
            result: $Utils.Optional<UserSessionCountAggregateOutputType> | number
          }
        }
      }
      PhoneOtp: {
        payload: Prisma.$PhoneOtpPayload<ExtArgs>
        fields: Prisma.PhoneOtpFieldRefs
        operations: {
          findUnique: {
            args: Prisma.PhoneOtpFindUniqueArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$PhoneOtpPayload> | null
          }
          findUniqueOrThrow: {
            args: Prisma.PhoneOtpFindUniqueOrThrowArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$PhoneOtpPayload>
          }
          findFirst: {
            args: Prisma.PhoneOtpFindFirstArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$PhoneOtpPayload> | null
          }
          findFirstOrThrow: {
            args: Prisma.PhoneOtpFindFirstOrThrowArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$PhoneOtpPayload>
          }
          findMany: {
            args: Prisma.PhoneOtpFindManyArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$PhoneOtpPayload>[]
          }
          create: {
            args: Prisma.PhoneOtpCreateArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$PhoneOtpPayload>
          }
          createMany: {
            args: Prisma.PhoneOtpCreateManyArgs<ExtArgs>
            result: BatchPayload
          }
          createManyAndReturn: {
            args: Prisma.PhoneOtpCreateManyAndReturnArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$PhoneOtpPayload>[]
          }
          delete: {
            args: Prisma.PhoneOtpDeleteArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$PhoneOtpPayload>
          }
          update: {
            args: Prisma.PhoneOtpUpdateArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$PhoneOtpPayload>
          }
          deleteMany: {
            args: Prisma.PhoneOtpDeleteManyArgs<ExtArgs>
            result: BatchPayload
          }
          updateMany: {
            args: Prisma.PhoneOtpUpdateManyArgs<ExtArgs>
            result: BatchPayload
          }
          updateManyAndReturn: {
            args: Prisma.PhoneOtpUpdateManyAndReturnArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$PhoneOtpPayload>[]
          }
          upsert: {
            args: Prisma.PhoneOtpUpsertArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$PhoneOtpPayload>
          }
          aggregate: {
            args: Prisma.PhoneOtpAggregateArgs<ExtArgs>
            result: $Utils.Optional<AggregatePhoneOtp>
          }
          groupBy: {
            args: Prisma.PhoneOtpGroupByArgs<ExtArgs>
            result: $Utils.Optional<PhoneOtpGroupByOutputType>[]
          }
          count: {
            args: Prisma.PhoneOtpCountArgs<ExtArgs>
            result: $Utils.Optional<PhoneOtpCountAggregateOutputType> | number
          }
        }
      }
      LoginFailure: {
        payload: Prisma.$LoginFailurePayload<ExtArgs>
        fields: Prisma.LoginFailureFieldRefs
        operations: {
          findUnique: {
            args: Prisma.LoginFailureFindUniqueArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$LoginFailurePayload> | null
          }
          findUniqueOrThrow: {
            args: Prisma.LoginFailureFindUniqueOrThrowArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$LoginFailurePayload>
          }
          findFirst: {
            args: Prisma.LoginFailureFindFirstArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$LoginFailurePayload> | null
          }
          findFirstOrThrow: {
            args: Prisma.LoginFailureFindFirstOrThrowArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$LoginFailurePayload>
          }
          findMany: {
            args: Prisma.LoginFailureFindManyArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$LoginFailurePayload>[]
          }
          create: {
            args: Prisma.LoginFailureCreateArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$LoginFailurePayload>
          }
          createMany: {
            args: Prisma.LoginFailureCreateManyArgs<ExtArgs>
            result: BatchPayload
          }
          createManyAndReturn: {
            args: Prisma.LoginFailureCreateManyAndReturnArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$LoginFailurePayload>[]
          }
          delete: {
            args: Prisma.LoginFailureDeleteArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$LoginFailurePayload>
          }
          update: {
            args: Prisma.LoginFailureUpdateArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$LoginFailurePayload>
          }
          deleteMany: {
            args: Prisma.LoginFailureDeleteManyArgs<ExtArgs>
            result: BatchPayload
          }
          updateMany: {
            args: Prisma.LoginFailureUpdateManyArgs<ExtArgs>
            result: BatchPayload
          }
          updateManyAndReturn: {
            args: Prisma.LoginFailureUpdateManyAndReturnArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$LoginFailurePayload>[]
          }
          upsert: {
            args: Prisma.LoginFailureUpsertArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$LoginFailurePayload>
          }
          aggregate: {
            args: Prisma.LoginFailureAggregateArgs<ExtArgs>
            result: $Utils.Optional<AggregateLoginFailure>
          }
          groupBy: {
            args: Prisma.LoginFailureGroupByArgs<ExtArgs>
            result: $Utils.Optional<LoginFailureGroupByOutputType>[]
          }
          count: {
            args: Prisma.LoginFailureCountArgs<ExtArgs>
            result: $Utils.Optional<LoginFailureCountAggregateOutputType> | number
          }
        }
      }
      AdminNotification: {
        payload: Prisma.$AdminNotificationPayload<ExtArgs>
        fields: Prisma.AdminNotificationFieldRefs
        operations: {
          findUnique: {
            args: Prisma.AdminNotificationFindUniqueArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$AdminNotificationPayload> | null
          }
          findUniqueOrThrow: {
            args: Prisma.AdminNotificationFindUniqueOrThrowArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$AdminNotificationPayload>
          }
          findFirst: {
            args: Prisma.AdminNotificationFindFirstArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$AdminNotificationPayload> | null
          }
          findFirstOrThrow: {
            args: Prisma.AdminNotificationFindFirstOrThrowArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$AdminNotificationPayload>
          }
          findMany: {
            args: Prisma.AdminNotificationFindManyArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$AdminNotificationPayload>[]
          }
          create: {
            args: Prisma.AdminNotificationCreateArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$AdminNotificationPayload>
          }
          createMany: {
            args: Prisma.AdminNotificationCreateManyArgs<ExtArgs>
            result: BatchPayload
          }
          createManyAndReturn: {
            args: Prisma.AdminNotificationCreateManyAndReturnArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$AdminNotificationPayload>[]
          }
          delete: {
            args: Prisma.AdminNotificationDeleteArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$AdminNotificationPayload>
          }
          update: {
            args: Prisma.AdminNotificationUpdateArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$AdminNotificationPayload>
          }
          deleteMany: {
            args: Prisma.AdminNotificationDeleteManyArgs<ExtArgs>
            result: BatchPayload
          }
          updateMany: {
            args: Prisma.AdminNotificationUpdateManyArgs<ExtArgs>
            result: BatchPayload
          }
          updateManyAndReturn: {
            args: Prisma.AdminNotificationUpdateManyAndReturnArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$AdminNotificationPayload>[]
          }
          upsert: {
            args: Prisma.AdminNotificationUpsertArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$AdminNotificationPayload>
          }
          aggregate: {
            args: Prisma.AdminNotificationAggregateArgs<ExtArgs>
            result: $Utils.Optional<AggregateAdminNotification>
          }
          groupBy: {
            args: Prisma.AdminNotificationGroupByArgs<ExtArgs>
            result: $Utils.Optional<AdminNotificationGroupByOutputType>[]
          }
          count: {
            args: Prisma.AdminNotificationCountArgs<ExtArgs>
            result: $Utils.Optional<AdminNotificationCountAggregateOutputType> | number
          }
        }
      }
      PointTransaction: {
        payload: Prisma.$PointTransactionPayload<ExtArgs>
        fields: Prisma.PointTransactionFieldRefs
        operations: {
          findUnique: {
            args: Prisma.PointTransactionFindUniqueArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$PointTransactionPayload> | null
          }
          findUniqueOrThrow: {
            args: Prisma.PointTransactionFindUniqueOrThrowArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$PointTransactionPayload>
          }
          findFirst: {
            args: Prisma.PointTransactionFindFirstArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$PointTransactionPayload> | null
          }
          findFirstOrThrow: {
            args: Prisma.PointTransactionFindFirstOrThrowArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$PointTransactionPayload>
          }
          findMany: {
            args: Prisma.PointTransactionFindManyArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$PointTransactionPayload>[]
          }
          create: {
            args: Prisma.PointTransactionCreateArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$PointTransactionPayload>
          }
          createMany: {
            args: Prisma.PointTransactionCreateManyArgs<ExtArgs>
            result: BatchPayload
          }
          createManyAndReturn: {
            args: Prisma.PointTransactionCreateManyAndReturnArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$PointTransactionPayload>[]
          }
          delete: {
            args: Prisma.PointTransactionDeleteArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$PointTransactionPayload>
          }
          update: {
            args: Prisma.PointTransactionUpdateArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$PointTransactionPayload>
          }
          deleteMany: {
            args: Prisma.PointTransactionDeleteManyArgs<ExtArgs>
            result: BatchPayload
          }
          updateMany: {
            args: Prisma.PointTransactionUpdateManyArgs<ExtArgs>
            result: BatchPayload
          }
          updateManyAndReturn: {
            args: Prisma.PointTransactionUpdateManyAndReturnArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$PointTransactionPayload>[]
          }
          upsert: {
            args: Prisma.PointTransactionUpsertArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$PointTransactionPayload>
          }
          aggregate: {
            args: Prisma.PointTransactionAggregateArgs<ExtArgs>
            result: $Utils.Optional<AggregatePointTransaction>
          }
          groupBy: {
            args: Prisma.PointTransactionGroupByArgs<ExtArgs>
            result: $Utils.Optional<PointTransactionGroupByOutputType>[]
          }
          count: {
            args: Prisma.PointTransactionCountArgs<ExtArgs>
            result: $Utils.Optional<PointTransactionCountAggregateOutputType> | number
          }
        }
      }
      Site: {
        payload: Prisma.$SitePayload<ExtArgs>
        fields: Prisma.SiteFieldRefs
        operations: {
          findUnique: {
            args: Prisma.SiteFindUniqueArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$SitePayload> | null
          }
          findUniqueOrThrow: {
            args: Prisma.SiteFindUniqueOrThrowArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$SitePayload>
          }
          findFirst: {
            args: Prisma.SiteFindFirstArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$SitePayload> | null
          }
          findFirstOrThrow: {
            args: Prisma.SiteFindFirstOrThrowArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$SitePayload>
          }
          findMany: {
            args: Prisma.SiteFindManyArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$SitePayload>[]
          }
          create: {
            args: Prisma.SiteCreateArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$SitePayload>
          }
          createMany: {
            args: Prisma.SiteCreateManyArgs<ExtArgs>
            result: BatchPayload
          }
          createManyAndReturn: {
            args: Prisma.SiteCreateManyAndReturnArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$SitePayload>[]
          }
          delete: {
            args: Prisma.SiteDeleteArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$SitePayload>
          }
          update: {
            args: Prisma.SiteUpdateArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$SitePayload>
          }
          deleteMany: {
            args: Prisma.SiteDeleteManyArgs<ExtArgs>
            result: BatchPayload
          }
          updateMany: {
            args: Prisma.SiteUpdateManyArgs<ExtArgs>
            result: BatchPayload
          }
          updateManyAndReturn: {
            args: Prisma.SiteUpdateManyAndReturnArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$SitePayload>[]
          }
          upsert: {
            args: Prisma.SiteUpsertArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$SitePayload>
          }
          aggregate: {
            args: Prisma.SiteAggregateArgs<ExtArgs>
            result: $Utils.Optional<AggregateSite>
          }
          groupBy: {
            args: Prisma.SiteGroupByArgs<ExtArgs>
            result: $Utils.Optional<SiteGroupByOutputType>[]
          }
          count: {
            args: Prisma.SiteCountArgs<ExtArgs>
            result: $Utils.Optional<SiteCountAggregateOutputType> | number
          }
        }
      }
      Report: {
        payload: Prisma.$ReportPayload<ExtArgs>
        fields: Prisma.ReportFieldRefs
        operations: {
          findUnique: {
            args: Prisma.ReportFindUniqueArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$ReportPayload> | null
          }
          findUniqueOrThrow: {
            args: Prisma.ReportFindUniqueOrThrowArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$ReportPayload>
          }
          findFirst: {
            args: Prisma.ReportFindFirstArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$ReportPayload> | null
          }
          findFirstOrThrow: {
            args: Prisma.ReportFindFirstOrThrowArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$ReportPayload>
          }
          findMany: {
            args: Prisma.ReportFindManyArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$ReportPayload>[]
          }
          create: {
            args: Prisma.ReportCreateArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$ReportPayload>
          }
          createMany: {
            args: Prisma.ReportCreateManyArgs<ExtArgs>
            result: BatchPayload
          }
          createManyAndReturn: {
            args: Prisma.ReportCreateManyAndReturnArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$ReportPayload>[]
          }
          delete: {
            args: Prisma.ReportDeleteArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$ReportPayload>
          }
          update: {
            args: Prisma.ReportUpdateArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$ReportPayload>
          }
          deleteMany: {
            args: Prisma.ReportDeleteManyArgs<ExtArgs>
            result: BatchPayload
          }
          updateMany: {
            args: Prisma.ReportUpdateManyArgs<ExtArgs>
            result: BatchPayload
          }
          updateManyAndReturn: {
            args: Prisma.ReportUpdateManyAndReturnArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$ReportPayload>[]
          }
          upsert: {
            args: Prisma.ReportUpsertArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$ReportPayload>
          }
          aggregate: {
            args: Prisma.ReportAggregateArgs<ExtArgs>
            result: $Utils.Optional<AggregateReport>
          }
          groupBy: {
            args: Prisma.ReportGroupByArgs<ExtArgs>
            result: $Utils.Optional<ReportGroupByOutputType>[]
          }
          count: {
            args: Prisma.ReportCountArgs<ExtArgs>
            result: $Utils.Optional<ReportCountAggregateOutputType> | number
          }
        }
      }
      ReportCoReporter: {
        payload: Prisma.$ReportCoReporterPayload<ExtArgs>
        fields: Prisma.ReportCoReporterFieldRefs
        operations: {
          findUnique: {
            args: Prisma.ReportCoReporterFindUniqueArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$ReportCoReporterPayload> | null
          }
          findUniqueOrThrow: {
            args: Prisma.ReportCoReporterFindUniqueOrThrowArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$ReportCoReporterPayload>
          }
          findFirst: {
            args: Prisma.ReportCoReporterFindFirstArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$ReportCoReporterPayload> | null
          }
          findFirstOrThrow: {
            args: Prisma.ReportCoReporterFindFirstOrThrowArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$ReportCoReporterPayload>
          }
          findMany: {
            args: Prisma.ReportCoReporterFindManyArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$ReportCoReporterPayload>[]
          }
          create: {
            args: Prisma.ReportCoReporterCreateArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$ReportCoReporterPayload>
          }
          createMany: {
            args: Prisma.ReportCoReporterCreateManyArgs<ExtArgs>
            result: BatchPayload
          }
          createManyAndReturn: {
            args: Prisma.ReportCoReporterCreateManyAndReturnArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$ReportCoReporterPayload>[]
          }
          delete: {
            args: Prisma.ReportCoReporterDeleteArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$ReportCoReporterPayload>
          }
          update: {
            args: Prisma.ReportCoReporterUpdateArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$ReportCoReporterPayload>
          }
          deleteMany: {
            args: Prisma.ReportCoReporterDeleteManyArgs<ExtArgs>
            result: BatchPayload
          }
          updateMany: {
            args: Prisma.ReportCoReporterUpdateManyArgs<ExtArgs>
            result: BatchPayload
          }
          updateManyAndReturn: {
            args: Prisma.ReportCoReporterUpdateManyAndReturnArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$ReportCoReporterPayload>[]
          }
          upsert: {
            args: Prisma.ReportCoReporterUpsertArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$ReportCoReporterPayload>
          }
          aggregate: {
            args: Prisma.ReportCoReporterAggregateArgs<ExtArgs>
            result: $Utils.Optional<AggregateReportCoReporter>
          }
          groupBy: {
            args: Prisma.ReportCoReporterGroupByArgs<ExtArgs>
            result: $Utils.Optional<ReportCoReporterGroupByOutputType>[]
          }
          count: {
            args: Prisma.ReportCoReporterCountArgs<ExtArgs>
            result: $Utils.Optional<ReportCoReporterCountAggregateOutputType> | number
          }
        }
      }
      CleanupEvent: {
        payload: Prisma.$CleanupEventPayload<ExtArgs>
        fields: Prisma.CleanupEventFieldRefs
        operations: {
          findUnique: {
            args: Prisma.CleanupEventFindUniqueArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$CleanupEventPayload> | null
          }
          findUniqueOrThrow: {
            args: Prisma.CleanupEventFindUniqueOrThrowArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$CleanupEventPayload>
          }
          findFirst: {
            args: Prisma.CleanupEventFindFirstArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$CleanupEventPayload> | null
          }
          findFirstOrThrow: {
            args: Prisma.CleanupEventFindFirstOrThrowArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$CleanupEventPayload>
          }
          findMany: {
            args: Prisma.CleanupEventFindManyArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$CleanupEventPayload>[]
          }
          create: {
            args: Prisma.CleanupEventCreateArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$CleanupEventPayload>
          }
          createMany: {
            args: Prisma.CleanupEventCreateManyArgs<ExtArgs>
            result: BatchPayload
          }
          createManyAndReturn: {
            args: Prisma.CleanupEventCreateManyAndReturnArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$CleanupEventPayload>[]
          }
          delete: {
            args: Prisma.CleanupEventDeleteArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$CleanupEventPayload>
          }
          update: {
            args: Prisma.CleanupEventUpdateArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$CleanupEventPayload>
          }
          deleteMany: {
            args: Prisma.CleanupEventDeleteManyArgs<ExtArgs>
            result: BatchPayload
          }
          updateMany: {
            args: Prisma.CleanupEventUpdateManyArgs<ExtArgs>
            result: BatchPayload
          }
          updateManyAndReturn: {
            args: Prisma.CleanupEventUpdateManyAndReturnArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$CleanupEventPayload>[]
          }
          upsert: {
            args: Prisma.CleanupEventUpsertArgs<ExtArgs>
            result: $Utils.PayloadToResult<Prisma.$CleanupEventPayload>
          }
          aggregate: {
            args: Prisma.CleanupEventAggregateArgs<ExtArgs>
            result: $Utils.Optional<AggregateCleanupEvent>
          }
          groupBy: {
            args: Prisma.CleanupEventGroupByArgs<ExtArgs>
            result: $Utils.Optional<CleanupEventGroupByOutputType>[]
          }
          count: {
            args: Prisma.CleanupEventCountArgs<ExtArgs>
            result: $Utils.Optional<CleanupEventCountAggregateOutputType> | number
          }
        }
      }
    }
  } & {
    other: {
      payload: any
      operations: {
        $executeRaw: {
          args: [query: TemplateStringsArray | Prisma.Sql, ...values: any[]],
          result: any
        }
        $executeRawUnsafe: {
          args: [query: string, ...values: any[]],
          result: any
        }
        $queryRaw: {
          args: [query: TemplateStringsArray | Prisma.Sql, ...values: any[]],
          result: any
        }
        $queryRawUnsafe: {
          args: [query: string, ...values: any[]],
          result: any
        }
      }
    }
  }
  export const defineExtension: $Extensions.ExtendsHook<"define", Prisma.TypeMapCb, $Extensions.DefaultArgs>
  export type DefaultPrismaClient = PrismaClient
  export type ErrorFormat = 'pretty' | 'colorless' | 'minimal'
  export interface PrismaClientOptions {
    /**
     * @default "colorless"
     */
    errorFormat?: ErrorFormat
    /**
     * @example
     * ```
     * // Shorthand for `emit: 'stdout'`
     * log: ['query', 'info', 'warn', 'error']
     * 
     * // Emit as events only
     * log: [
     *   { emit: 'event', level: 'query' },
     *   { emit: 'event', level: 'info' },
     *   { emit: 'event', level: 'warn' }
     *   { emit: 'event', level: 'error' }
     * ]
     * 
     * / Emit as events and log to stdout
     * og: [
     *  { emit: 'stdout', level: 'query' },
     *  { emit: 'stdout', level: 'info' },
     *  { emit: 'stdout', level: 'warn' }
     *  { emit: 'stdout', level: 'error' }
     * 
     * ```
     * Read more in our [docs](https://pris.ly/d/logging).
     */
    log?: (LogLevel | LogDefinition)[]
    /**
     * The default values for transactionOptions
     * maxWait ?= 2000
     * timeout ?= 5000
     */
    transactionOptions?: {
      maxWait?: number
      timeout?: number
      isolationLevel?: Prisma.TransactionIsolationLevel
    }
    /**
     * Instance of a Driver Adapter, e.g., like one provided by `@prisma/adapter-planetscale`
     */
    adapter?: runtime.SqlDriverAdapterFactory
    /**
     * Prisma Accelerate URL allowing the client to connect through Accelerate instead of a direct database.
     */
    accelerateUrl?: string
    /**
     * Global configuration for omitting model fields by default.
     * 
     * @example
     * ```
     * const prisma = new PrismaClient({
     *   omit: {
     *     user: {
     *       password: true
     *     }
     *   }
     * })
     * ```
     */
    omit?: Prisma.GlobalOmitConfig
    /**
     * SQL commenter plugins that add metadata to SQL queries as comments.
     * Comments follow the sqlcommenter format: https://google.github.io/sqlcommenter/
     * 
     * @example
     * ```
     * const prisma = new PrismaClient({
     *   adapter,
     *   comments: [
     *     traceContext(),
     *     queryInsights(),
     *   ],
     * })
     * ```
     */
    comments?: runtime.SqlCommenterPlugin[]
  }
  export type GlobalOmitConfig = {
    user?: UserOmit
    userSession?: UserSessionOmit
    phoneOtp?: PhoneOtpOmit
    loginFailure?: LoginFailureOmit
    adminNotification?: AdminNotificationOmit
    pointTransaction?: PointTransactionOmit
    site?: SiteOmit
    report?: ReportOmit
    reportCoReporter?: ReportCoReporterOmit
    cleanupEvent?: CleanupEventOmit
  }

  /* Types for Logging */
  export type LogLevel = 'info' | 'query' | 'warn' | 'error'
  export type LogDefinition = {
    level: LogLevel
    emit: 'stdout' | 'event'
  }

  export type CheckIsLogLevel<T> = T extends LogLevel ? T : never;

  export type GetLogType<T> = CheckIsLogLevel<
    T extends LogDefinition ? T['level'] : T
  >;

  export type GetEvents<T extends any[]> = T extends Array<LogLevel | LogDefinition>
    ? GetLogType<T[number]>
    : never;

  export type QueryEvent = {
    timestamp: Date
    query: string
    params: string
    duration: number
    target: string
  }

  export type LogEvent = {
    timestamp: Date
    message: string
    target: string
  }
  /* End Types for Logging */


  export type PrismaAction =
    | 'findUnique'
    | 'findUniqueOrThrow'
    | 'findMany'
    | 'findFirst'
    | 'findFirstOrThrow'
    | 'create'
    | 'createMany'
    | 'createManyAndReturn'
    | 'update'
    | 'updateMany'
    | 'updateManyAndReturn'
    | 'upsert'
    | 'delete'
    | 'deleteMany'
    | 'executeRaw'
    | 'queryRaw'
    | 'aggregate'
    | 'count'
    | 'runCommandRaw'
    | 'findRaw'
    | 'groupBy'

  // tested in getLogLevel.test.ts
  export function getLogLevel(log: Array<LogLevel | LogDefinition>): LogLevel | undefined;

  /**
   * `PrismaClient` proxy available in interactive transactions.
   */
  export type TransactionClient = Omit<Prisma.DefaultPrismaClient, runtime.ITXClientDenyList>

  export type Datasource = {
    url?: string
  }

  /**
   * Count Types
   */


  /**
   * Count Type UserCountOutputType
   */

  export type UserCountOutputType = {
    reports: number
    moderatedReports: number
    adminNotifications: number
    pointTransactions: number
    coReportedReports: number
    sessions: number
  }

  export type UserCountOutputTypeSelect<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    reports?: boolean | UserCountOutputTypeCountReportsArgs
    moderatedReports?: boolean | UserCountOutputTypeCountModeratedReportsArgs
    adminNotifications?: boolean | UserCountOutputTypeCountAdminNotificationsArgs
    pointTransactions?: boolean | UserCountOutputTypeCountPointTransactionsArgs
    coReportedReports?: boolean | UserCountOutputTypeCountCoReportedReportsArgs
    sessions?: boolean | UserCountOutputTypeCountSessionsArgs
  }

  // Custom InputTypes
  /**
   * UserCountOutputType without action
   */
  export type UserCountOutputTypeDefaultArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the UserCountOutputType
     */
    select?: UserCountOutputTypeSelect<ExtArgs> | null
  }

  /**
   * UserCountOutputType without action
   */
  export type UserCountOutputTypeCountReportsArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    where?: ReportWhereInput
  }

  /**
   * UserCountOutputType without action
   */
  export type UserCountOutputTypeCountModeratedReportsArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    where?: ReportWhereInput
  }

  /**
   * UserCountOutputType without action
   */
  export type UserCountOutputTypeCountAdminNotificationsArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    where?: AdminNotificationWhereInput
  }

  /**
   * UserCountOutputType without action
   */
  export type UserCountOutputTypeCountPointTransactionsArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    where?: PointTransactionWhereInput
  }

  /**
   * UserCountOutputType without action
   */
  export type UserCountOutputTypeCountCoReportedReportsArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    where?: ReportCoReporterWhereInput
  }

  /**
   * UserCountOutputType without action
   */
  export type UserCountOutputTypeCountSessionsArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    where?: UserSessionWhereInput
  }


  /**
   * Count Type SiteCountOutputType
   */

  export type SiteCountOutputType = {
    reports: number
    events: number
  }

  export type SiteCountOutputTypeSelect<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    reports?: boolean | SiteCountOutputTypeCountReportsArgs
    events?: boolean | SiteCountOutputTypeCountEventsArgs
  }

  // Custom InputTypes
  /**
   * SiteCountOutputType without action
   */
  export type SiteCountOutputTypeDefaultArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the SiteCountOutputType
     */
    select?: SiteCountOutputTypeSelect<ExtArgs> | null
  }

  /**
   * SiteCountOutputType without action
   */
  export type SiteCountOutputTypeCountReportsArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    where?: ReportWhereInput
  }

  /**
   * SiteCountOutputType without action
   */
  export type SiteCountOutputTypeCountEventsArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    where?: CleanupEventWhereInput
  }


  /**
   * Count Type ReportCountOutputType
   */

  export type ReportCountOutputType = {
    potentialDuplicates: number
    coReporters: number
  }

  export type ReportCountOutputTypeSelect<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    potentialDuplicates?: boolean | ReportCountOutputTypeCountPotentialDuplicatesArgs
    coReporters?: boolean | ReportCountOutputTypeCountCoReportersArgs
  }

  // Custom InputTypes
  /**
   * ReportCountOutputType without action
   */
  export type ReportCountOutputTypeDefaultArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the ReportCountOutputType
     */
    select?: ReportCountOutputTypeSelect<ExtArgs> | null
  }

  /**
   * ReportCountOutputType without action
   */
  export type ReportCountOutputTypeCountPotentialDuplicatesArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    where?: ReportWhereInput
  }

  /**
   * ReportCountOutputType without action
   */
  export type ReportCountOutputTypeCountCoReportersArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    where?: ReportCoReporterWhereInput
  }


  /**
   * Models
   */

  /**
   * Model User
   */

  export type AggregateUser = {
    _count: UserCountAggregateOutputType | null
    _avg: UserAvgAggregateOutputType | null
    _sum: UserSumAggregateOutputType | null
    _min: UserMinAggregateOutputType | null
    _max: UserMaxAggregateOutputType | null
  }

  export type UserAvgAggregateOutputType = {
    pointsBalance: number | null
    totalPointsEarned: number | null
    totalPointsSpent: number | null
  }

  export type UserSumAggregateOutputType = {
    pointsBalance: number | null
    totalPointsEarned: number | null
    totalPointsSpent: number | null
  }

  export type UserMinAggregateOutputType = {
    id: string | null
    createdAt: Date | null
    updatedAt: Date | null
    firstName: string | null
    lastName: string | null
    email: string | null
    phoneNumber: string | null
    passwordHash: string | null
    role: $Enums.Role | null
    status: $Enums.UserStatus | null
    isPhoneVerified: boolean | null
    pointsBalance: number | null
    totalPointsEarned: number | null
    totalPointsSpent: number | null
    lastActiveAt: Date | null
  }

  export type UserMaxAggregateOutputType = {
    id: string | null
    createdAt: Date | null
    updatedAt: Date | null
    firstName: string | null
    lastName: string | null
    email: string | null
    phoneNumber: string | null
    passwordHash: string | null
    role: $Enums.Role | null
    status: $Enums.UserStatus | null
    isPhoneVerified: boolean | null
    pointsBalance: number | null
    totalPointsEarned: number | null
    totalPointsSpent: number | null
    lastActiveAt: Date | null
  }

  export type UserCountAggregateOutputType = {
    id: number
    createdAt: number
    updatedAt: number
    firstName: number
    lastName: number
    email: number
    phoneNumber: number
    passwordHash: number
    role: number
    status: number
    isPhoneVerified: number
    pointsBalance: number
    totalPointsEarned: number
    totalPointsSpent: number
    lastActiveAt: number
    _all: number
  }


  export type UserAvgAggregateInputType = {
    pointsBalance?: true
    totalPointsEarned?: true
    totalPointsSpent?: true
  }

  export type UserSumAggregateInputType = {
    pointsBalance?: true
    totalPointsEarned?: true
    totalPointsSpent?: true
  }

  export type UserMinAggregateInputType = {
    id?: true
    createdAt?: true
    updatedAt?: true
    firstName?: true
    lastName?: true
    email?: true
    phoneNumber?: true
    passwordHash?: true
    role?: true
    status?: true
    isPhoneVerified?: true
    pointsBalance?: true
    totalPointsEarned?: true
    totalPointsSpent?: true
    lastActiveAt?: true
  }

  export type UserMaxAggregateInputType = {
    id?: true
    createdAt?: true
    updatedAt?: true
    firstName?: true
    lastName?: true
    email?: true
    phoneNumber?: true
    passwordHash?: true
    role?: true
    status?: true
    isPhoneVerified?: true
    pointsBalance?: true
    totalPointsEarned?: true
    totalPointsSpent?: true
    lastActiveAt?: true
  }

  export type UserCountAggregateInputType = {
    id?: true
    createdAt?: true
    updatedAt?: true
    firstName?: true
    lastName?: true
    email?: true
    phoneNumber?: true
    passwordHash?: true
    role?: true
    status?: true
    isPhoneVerified?: true
    pointsBalance?: true
    totalPointsEarned?: true
    totalPointsSpent?: true
    lastActiveAt?: true
    _all?: true
  }

  export type UserAggregateArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Filter which User to aggregate.
     */
    where?: UserWhereInput
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/sorting Sorting Docs}
     * 
     * Determine the order of Users to fetch.
     */
    orderBy?: UserOrderByWithRelationInput | UserOrderByWithRelationInput[]
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination#cursor-based-pagination Cursor Docs}
     * 
     * Sets the start position
     */
    cursor?: UserWhereUniqueInput
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination Pagination Docs}
     * 
     * Take `±n` Users from the position of the cursor.
     */
    take?: number
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination Pagination Docs}
     * 
     * Skip the first `n` Users.
     */
    skip?: number
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/aggregations Aggregation Docs}
     * 
     * Count returned Users
    **/
    _count?: true | UserCountAggregateInputType
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/aggregations Aggregation Docs}
     * 
     * Select which fields to average
    **/
    _avg?: UserAvgAggregateInputType
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/aggregations Aggregation Docs}
     * 
     * Select which fields to sum
    **/
    _sum?: UserSumAggregateInputType
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/aggregations Aggregation Docs}
     * 
     * Select which fields to find the minimum value
    **/
    _min?: UserMinAggregateInputType
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/aggregations Aggregation Docs}
     * 
     * Select which fields to find the maximum value
    **/
    _max?: UserMaxAggregateInputType
  }

  export type GetUserAggregateType<T extends UserAggregateArgs> = {
        [P in keyof T & keyof AggregateUser]: P extends '_count' | 'count'
      ? T[P] extends true
        ? number
        : GetScalarType<T[P], AggregateUser[P]>
      : GetScalarType<T[P], AggregateUser[P]>
  }




  export type UserGroupByArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    where?: UserWhereInput
    orderBy?: UserOrderByWithAggregationInput | UserOrderByWithAggregationInput[]
    by: UserScalarFieldEnum[] | UserScalarFieldEnum
    having?: UserScalarWhereWithAggregatesInput
    take?: number
    skip?: number
    _count?: UserCountAggregateInputType | true
    _avg?: UserAvgAggregateInputType
    _sum?: UserSumAggregateInputType
    _min?: UserMinAggregateInputType
    _max?: UserMaxAggregateInputType
  }

  export type UserGroupByOutputType = {
    id: string
    createdAt: Date
    updatedAt: Date
    firstName: string
    lastName: string
    email: string
    phoneNumber: string
    passwordHash: string
    role: $Enums.Role
    status: $Enums.UserStatus
    isPhoneVerified: boolean
    pointsBalance: number
    totalPointsEarned: number
    totalPointsSpent: number
    lastActiveAt: Date | null
    _count: UserCountAggregateOutputType | null
    _avg: UserAvgAggregateOutputType | null
    _sum: UserSumAggregateOutputType | null
    _min: UserMinAggregateOutputType | null
    _max: UserMaxAggregateOutputType | null
  }

  type GetUserGroupByPayload<T extends UserGroupByArgs> = Prisma.PrismaPromise<
    Array<
      PickEnumerable<UserGroupByOutputType, T['by']> &
        {
          [P in ((keyof T) & (keyof UserGroupByOutputType))]: P extends '_count'
            ? T[P] extends boolean
              ? number
              : GetScalarType<T[P], UserGroupByOutputType[P]>
            : GetScalarType<T[P], UserGroupByOutputType[P]>
        }
      >
    >


  export type UserSelect<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = $Extensions.GetSelect<{
    id?: boolean
    createdAt?: boolean
    updatedAt?: boolean
    firstName?: boolean
    lastName?: boolean
    email?: boolean
    phoneNumber?: boolean
    passwordHash?: boolean
    role?: boolean
    status?: boolean
    isPhoneVerified?: boolean
    pointsBalance?: boolean
    totalPointsEarned?: boolean
    totalPointsSpent?: boolean
    lastActiveAt?: boolean
    reports?: boolean | User$reportsArgs<ExtArgs>
    moderatedReports?: boolean | User$moderatedReportsArgs<ExtArgs>
    adminNotifications?: boolean | User$adminNotificationsArgs<ExtArgs>
    pointTransactions?: boolean | User$pointTransactionsArgs<ExtArgs>
    coReportedReports?: boolean | User$coReportedReportsArgs<ExtArgs>
    sessions?: boolean | User$sessionsArgs<ExtArgs>
    _count?: boolean | UserCountOutputTypeDefaultArgs<ExtArgs>
  }, ExtArgs["result"]["user"]>

  export type UserSelectCreateManyAndReturn<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = $Extensions.GetSelect<{
    id?: boolean
    createdAt?: boolean
    updatedAt?: boolean
    firstName?: boolean
    lastName?: boolean
    email?: boolean
    phoneNumber?: boolean
    passwordHash?: boolean
    role?: boolean
    status?: boolean
    isPhoneVerified?: boolean
    pointsBalance?: boolean
    totalPointsEarned?: boolean
    totalPointsSpent?: boolean
    lastActiveAt?: boolean
  }, ExtArgs["result"]["user"]>

  export type UserSelectUpdateManyAndReturn<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = $Extensions.GetSelect<{
    id?: boolean
    createdAt?: boolean
    updatedAt?: boolean
    firstName?: boolean
    lastName?: boolean
    email?: boolean
    phoneNumber?: boolean
    passwordHash?: boolean
    role?: boolean
    status?: boolean
    isPhoneVerified?: boolean
    pointsBalance?: boolean
    totalPointsEarned?: boolean
    totalPointsSpent?: boolean
    lastActiveAt?: boolean
  }, ExtArgs["result"]["user"]>

  export type UserSelectScalar = {
    id?: boolean
    createdAt?: boolean
    updatedAt?: boolean
    firstName?: boolean
    lastName?: boolean
    email?: boolean
    phoneNumber?: boolean
    passwordHash?: boolean
    role?: boolean
    status?: boolean
    isPhoneVerified?: boolean
    pointsBalance?: boolean
    totalPointsEarned?: boolean
    totalPointsSpent?: boolean
    lastActiveAt?: boolean
  }

  export type UserOmit<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = $Extensions.GetOmit<"id" | "createdAt" | "updatedAt" | "firstName" | "lastName" | "email" | "phoneNumber" | "passwordHash" | "role" | "status" | "isPhoneVerified" | "pointsBalance" | "totalPointsEarned" | "totalPointsSpent" | "lastActiveAt", ExtArgs["result"]["user"]>
  export type UserInclude<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    reports?: boolean | User$reportsArgs<ExtArgs>
    moderatedReports?: boolean | User$moderatedReportsArgs<ExtArgs>
    adminNotifications?: boolean | User$adminNotificationsArgs<ExtArgs>
    pointTransactions?: boolean | User$pointTransactionsArgs<ExtArgs>
    coReportedReports?: boolean | User$coReportedReportsArgs<ExtArgs>
    sessions?: boolean | User$sessionsArgs<ExtArgs>
    _count?: boolean | UserCountOutputTypeDefaultArgs<ExtArgs>
  }
  export type UserIncludeCreateManyAndReturn<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {}
  export type UserIncludeUpdateManyAndReturn<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {}

  export type $UserPayload<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    name: "User"
    objects: {
      reports: Prisma.$ReportPayload<ExtArgs>[]
      moderatedReports: Prisma.$ReportPayload<ExtArgs>[]
      adminNotifications: Prisma.$AdminNotificationPayload<ExtArgs>[]
      pointTransactions: Prisma.$PointTransactionPayload<ExtArgs>[]
      coReportedReports: Prisma.$ReportCoReporterPayload<ExtArgs>[]
      sessions: Prisma.$UserSessionPayload<ExtArgs>[]
    }
    scalars: $Extensions.GetPayloadResult<{
      id: string
      createdAt: Date
      updatedAt: Date
      firstName: string
      lastName: string
      email: string
      phoneNumber: string
      passwordHash: string
      role: $Enums.Role
      status: $Enums.UserStatus
      isPhoneVerified: boolean
      pointsBalance: number
      totalPointsEarned: number
      totalPointsSpent: number
      lastActiveAt: Date | null
    }, ExtArgs["result"]["user"]>
    composites: {}
  }

  type UserGetPayload<S extends boolean | null | undefined | UserDefaultArgs> = $Result.GetResult<Prisma.$UserPayload, S>

  type UserCountArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> =
    Omit<UserFindManyArgs, 'select' | 'include' | 'distinct' | 'omit'> & {
      select?: UserCountAggregateInputType | true
    }

  export interface UserDelegate<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs, GlobalOmitOptions = {}> {
    [K: symbol]: { types: Prisma.TypeMap<ExtArgs>['model']['User'], meta: { name: 'User' } }
    /**
     * Find zero or one User that matches the filter.
     * @param {UserFindUniqueArgs} args - Arguments to find a User
     * @example
     * // Get one User
     * const user = await prisma.user.findUnique({
     *   where: {
     *     // ... provide filter here
     *   }
     * })
     */
    findUnique<T extends UserFindUniqueArgs>(args: SelectSubset<T, UserFindUniqueArgs<ExtArgs>>): Prisma__UserClient<$Result.GetResult<Prisma.$UserPayload<ExtArgs>, T, "findUnique", GlobalOmitOptions> | null, null, ExtArgs, GlobalOmitOptions>

    /**
     * Find one User that matches the filter or throw an error with `error.code='P2025'`
     * if no matches were found.
     * @param {UserFindUniqueOrThrowArgs} args - Arguments to find a User
     * @example
     * // Get one User
     * const user = await prisma.user.findUniqueOrThrow({
     *   where: {
     *     // ... provide filter here
     *   }
     * })
     */
    findUniqueOrThrow<T extends UserFindUniqueOrThrowArgs>(args: SelectSubset<T, UserFindUniqueOrThrowArgs<ExtArgs>>): Prisma__UserClient<$Result.GetResult<Prisma.$UserPayload<ExtArgs>, T, "findUniqueOrThrow", GlobalOmitOptions>, never, ExtArgs, GlobalOmitOptions>

    /**
     * Find the first User that matches the filter.
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * @param {UserFindFirstArgs} args - Arguments to find a User
     * @example
     * // Get one User
     * const user = await prisma.user.findFirst({
     *   where: {
     *     // ... provide filter here
     *   }
     * })
     */
    findFirst<T extends UserFindFirstArgs>(args?: SelectSubset<T, UserFindFirstArgs<ExtArgs>>): Prisma__UserClient<$Result.GetResult<Prisma.$UserPayload<ExtArgs>, T, "findFirst", GlobalOmitOptions> | null, null, ExtArgs, GlobalOmitOptions>

    /**
     * Find the first User that matches the filter or
     * throw `PrismaKnownClientError` with `P2025` code if no matches were found.
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * @param {UserFindFirstOrThrowArgs} args - Arguments to find a User
     * @example
     * // Get one User
     * const user = await prisma.user.findFirstOrThrow({
     *   where: {
     *     // ... provide filter here
     *   }
     * })
     */
    findFirstOrThrow<T extends UserFindFirstOrThrowArgs>(args?: SelectSubset<T, UserFindFirstOrThrowArgs<ExtArgs>>): Prisma__UserClient<$Result.GetResult<Prisma.$UserPayload<ExtArgs>, T, "findFirstOrThrow", GlobalOmitOptions>, never, ExtArgs, GlobalOmitOptions>

    /**
     * Find zero or more Users that matches the filter.
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * @param {UserFindManyArgs} args - Arguments to filter and select certain fields only.
     * @example
     * // Get all Users
     * const users = await prisma.user.findMany()
     * 
     * // Get first 10 Users
     * const users = await prisma.user.findMany({ take: 10 })
     * 
     * // Only select the `id`
     * const userWithIdOnly = await prisma.user.findMany({ select: { id: true } })
     * 
     */
    findMany<T extends UserFindManyArgs>(args?: SelectSubset<T, UserFindManyArgs<ExtArgs>>): Prisma.PrismaPromise<$Result.GetResult<Prisma.$UserPayload<ExtArgs>, T, "findMany", GlobalOmitOptions>>

    /**
     * Create a User.
     * @param {UserCreateArgs} args - Arguments to create a User.
     * @example
     * // Create one User
     * const User = await prisma.user.create({
     *   data: {
     *     // ... data to create a User
     *   }
     * })
     * 
     */
    create<T extends UserCreateArgs>(args: SelectSubset<T, UserCreateArgs<ExtArgs>>): Prisma__UserClient<$Result.GetResult<Prisma.$UserPayload<ExtArgs>, T, "create", GlobalOmitOptions>, never, ExtArgs, GlobalOmitOptions>

    /**
     * Create many Users.
     * @param {UserCreateManyArgs} args - Arguments to create many Users.
     * @example
     * // Create many Users
     * const user = await prisma.user.createMany({
     *   data: [
     *     // ... provide data here
     *   ]
     * })
     *     
     */
    createMany<T extends UserCreateManyArgs>(args?: SelectSubset<T, UserCreateManyArgs<ExtArgs>>): Prisma.PrismaPromise<BatchPayload>

    /**
     * Create many Users and returns the data saved in the database.
     * @param {UserCreateManyAndReturnArgs} args - Arguments to create many Users.
     * @example
     * // Create many Users
     * const user = await prisma.user.createManyAndReturn({
     *   data: [
     *     // ... provide data here
     *   ]
     * })
     * 
     * // Create many Users and only return the `id`
     * const userWithIdOnly = await prisma.user.createManyAndReturn({
     *   select: { id: true },
     *   data: [
     *     // ... provide data here
     *   ]
     * })
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * 
     */
    createManyAndReturn<T extends UserCreateManyAndReturnArgs>(args?: SelectSubset<T, UserCreateManyAndReturnArgs<ExtArgs>>): Prisma.PrismaPromise<$Result.GetResult<Prisma.$UserPayload<ExtArgs>, T, "createManyAndReturn", GlobalOmitOptions>>

    /**
     * Delete a User.
     * @param {UserDeleteArgs} args - Arguments to delete one User.
     * @example
     * // Delete one User
     * const User = await prisma.user.delete({
     *   where: {
     *     // ... filter to delete one User
     *   }
     * })
     * 
     */
    delete<T extends UserDeleteArgs>(args: SelectSubset<T, UserDeleteArgs<ExtArgs>>): Prisma__UserClient<$Result.GetResult<Prisma.$UserPayload<ExtArgs>, T, "delete", GlobalOmitOptions>, never, ExtArgs, GlobalOmitOptions>

    /**
     * Update one User.
     * @param {UserUpdateArgs} args - Arguments to update one User.
     * @example
     * // Update one User
     * const user = await prisma.user.update({
     *   where: {
     *     // ... provide filter here
     *   },
     *   data: {
     *     // ... provide data here
     *   }
     * })
     * 
     */
    update<T extends UserUpdateArgs>(args: SelectSubset<T, UserUpdateArgs<ExtArgs>>): Prisma__UserClient<$Result.GetResult<Prisma.$UserPayload<ExtArgs>, T, "update", GlobalOmitOptions>, never, ExtArgs, GlobalOmitOptions>

    /**
     * Delete zero or more Users.
     * @param {UserDeleteManyArgs} args - Arguments to filter Users to delete.
     * @example
     * // Delete a few Users
     * const { count } = await prisma.user.deleteMany({
     *   where: {
     *     // ... provide filter here
     *   }
     * })
     * 
     */
    deleteMany<T extends UserDeleteManyArgs>(args?: SelectSubset<T, UserDeleteManyArgs<ExtArgs>>): Prisma.PrismaPromise<BatchPayload>

    /**
     * Update zero or more Users.
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * @param {UserUpdateManyArgs} args - Arguments to update one or more rows.
     * @example
     * // Update many Users
     * const user = await prisma.user.updateMany({
     *   where: {
     *     // ... provide filter here
     *   },
     *   data: {
     *     // ... provide data here
     *   }
     * })
     * 
     */
    updateMany<T extends UserUpdateManyArgs>(args: SelectSubset<T, UserUpdateManyArgs<ExtArgs>>): Prisma.PrismaPromise<BatchPayload>

    /**
     * Update zero or more Users and returns the data updated in the database.
     * @param {UserUpdateManyAndReturnArgs} args - Arguments to update many Users.
     * @example
     * // Update many Users
     * const user = await prisma.user.updateManyAndReturn({
     *   where: {
     *     // ... provide filter here
     *   },
     *   data: [
     *     // ... provide data here
     *   ]
     * })
     * 
     * // Update zero or more Users and only return the `id`
     * const userWithIdOnly = await prisma.user.updateManyAndReturn({
     *   select: { id: true },
     *   where: {
     *     // ... provide filter here
     *   },
     *   data: [
     *     // ... provide data here
     *   ]
     * })
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * 
     */
    updateManyAndReturn<T extends UserUpdateManyAndReturnArgs>(args: SelectSubset<T, UserUpdateManyAndReturnArgs<ExtArgs>>): Prisma.PrismaPromise<$Result.GetResult<Prisma.$UserPayload<ExtArgs>, T, "updateManyAndReturn", GlobalOmitOptions>>

    /**
     * Create or update one User.
     * @param {UserUpsertArgs} args - Arguments to update or create a User.
     * @example
     * // Update or create a User
     * const user = await prisma.user.upsert({
     *   create: {
     *     // ... data to create a User
     *   },
     *   update: {
     *     // ... in case it already exists, update
     *   },
     *   where: {
     *     // ... the filter for the User we want to update
     *   }
     * })
     */
    upsert<T extends UserUpsertArgs>(args: SelectSubset<T, UserUpsertArgs<ExtArgs>>): Prisma__UserClient<$Result.GetResult<Prisma.$UserPayload<ExtArgs>, T, "upsert", GlobalOmitOptions>, never, ExtArgs, GlobalOmitOptions>


    /**
     * Count the number of Users.
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * @param {UserCountArgs} args - Arguments to filter Users to count.
     * @example
     * // Count the number of Users
     * const count = await prisma.user.count({
     *   where: {
     *     // ... the filter for the Users we want to count
     *   }
     * })
    **/
    count<T extends UserCountArgs>(
      args?: Subset<T, UserCountArgs>,
    ): Prisma.PrismaPromise<
      T extends $Utils.Record<'select', any>
        ? T['select'] extends true
          ? number
          : GetScalarType<T['select'], UserCountAggregateOutputType>
        : number
    >

    /**
     * Allows you to perform aggregations operations on a User.
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * @param {UserAggregateArgs} args - Select which aggregations you would like to apply and on what fields.
     * @example
     * // Ordered by age ascending
     * // Where email contains prisma.io
     * // Limited to the 10 users
     * const aggregations = await prisma.user.aggregate({
     *   _avg: {
     *     age: true,
     *   },
     *   where: {
     *     email: {
     *       contains: "prisma.io",
     *     },
     *   },
     *   orderBy: {
     *     age: "asc",
     *   },
     *   take: 10,
     * })
    **/
    aggregate<T extends UserAggregateArgs>(args: Subset<T, UserAggregateArgs>): Prisma.PrismaPromise<GetUserAggregateType<T>>

    /**
     * Group by User.
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * @param {UserGroupByArgs} args - Group by arguments.
     * @example
     * // Group by city, order by createdAt, get count
     * const result = await prisma.user.groupBy({
     *   by: ['city', 'createdAt'],
     *   orderBy: {
     *     createdAt: true
     *   },
     *   _count: {
     *     _all: true
     *   },
     * })
     * 
    **/
    groupBy<
      T extends UserGroupByArgs,
      HasSelectOrTake extends Or<
        Extends<'skip', Keys<T>>,
        Extends<'take', Keys<T>>
      >,
      OrderByArg extends True extends HasSelectOrTake
        ? { orderBy: UserGroupByArgs['orderBy'] }
        : { orderBy?: UserGroupByArgs['orderBy'] },
      OrderFields extends ExcludeUnderscoreKeys<Keys<MaybeTupleToUnion<T['orderBy']>>>,
      ByFields extends MaybeTupleToUnion<T['by']>,
      ByValid extends Has<ByFields, OrderFields>,
      HavingFields extends GetHavingFields<T['having']>,
      HavingValid extends Has<ByFields, HavingFields>,
      ByEmpty extends T['by'] extends never[] ? True : False,
      InputErrors extends ByEmpty extends True
      ? `Error: "by" must not be empty.`
      : HavingValid extends False
      ? {
          [P in HavingFields]: P extends ByFields
            ? never
            : P extends string
            ? `Error: Field "${P}" used in "having" needs to be provided in "by".`
            : [
                Error,
                'Field ',
                P,
                ` in "having" needs to be provided in "by"`,
              ]
        }[HavingFields]
      : 'take' extends Keys<T>
      ? 'orderBy' extends Keys<T>
        ? ByValid extends True
          ? {}
          : {
              [P in OrderFields]: P extends ByFields
                ? never
                : `Error: Field "${P}" in "orderBy" needs to be provided in "by"`
            }[OrderFields]
        : 'Error: If you provide "take", you also need to provide "orderBy"'
      : 'skip' extends Keys<T>
      ? 'orderBy' extends Keys<T>
        ? ByValid extends True
          ? {}
          : {
              [P in OrderFields]: P extends ByFields
                ? never
                : `Error: Field "${P}" in "orderBy" needs to be provided in "by"`
            }[OrderFields]
        : 'Error: If you provide "skip", you also need to provide "orderBy"'
      : ByValid extends True
      ? {}
      : {
          [P in OrderFields]: P extends ByFields
            ? never
            : `Error: Field "${P}" in "orderBy" needs to be provided in "by"`
        }[OrderFields]
    >(args: SubsetIntersection<T, UserGroupByArgs, OrderByArg> & InputErrors): {} extends InputErrors ? GetUserGroupByPayload<T> : Prisma.PrismaPromise<InputErrors>
  /**
   * Fields of the User model
   */
  readonly fields: UserFieldRefs;
  }

  /**
   * The delegate class that acts as a "Promise-like" for User.
   * Why is this prefixed with `Prisma__`?
   * Because we want to prevent naming conflicts as mentioned in
   * https://github.com/prisma/prisma-client-js/issues/707
   */
  export interface Prisma__UserClient<T, Null = never, ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs, GlobalOmitOptions = {}> extends Prisma.PrismaPromise<T> {
    readonly [Symbol.toStringTag]: "PrismaPromise"
    reports<T extends User$reportsArgs<ExtArgs> = {}>(args?: Subset<T, User$reportsArgs<ExtArgs>>): Prisma.PrismaPromise<$Result.GetResult<Prisma.$ReportPayload<ExtArgs>, T, "findMany", GlobalOmitOptions> | Null>
    moderatedReports<T extends User$moderatedReportsArgs<ExtArgs> = {}>(args?: Subset<T, User$moderatedReportsArgs<ExtArgs>>): Prisma.PrismaPromise<$Result.GetResult<Prisma.$ReportPayload<ExtArgs>, T, "findMany", GlobalOmitOptions> | Null>
    adminNotifications<T extends User$adminNotificationsArgs<ExtArgs> = {}>(args?: Subset<T, User$adminNotificationsArgs<ExtArgs>>): Prisma.PrismaPromise<$Result.GetResult<Prisma.$AdminNotificationPayload<ExtArgs>, T, "findMany", GlobalOmitOptions> | Null>
    pointTransactions<T extends User$pointTransactionsArgs<ExtArgs> = {}>(args?: Subset<T, User$pointTransactionsArgs<ExtArgs>>): Prisma.PrismaPromise<$Result.GetResult<Prisma.$PointTransactionPayload<ExtArgs>, T, "findMany", GlobalOmitOptions> | Null>
    coReportedReports<T extends User$coReportedReportsArgs<ExtArgs> = {}>(args?: Subset<T, User$coReportedReportsArgs<ExtArgs>>): Prisma.PrismaPromise<$Result.GetResult<Prisma.$ReportCoReporterPayload<ExtArgs>, T, "findMany", GlobalOmitOptions> | Null>
    sessions<T extends User$sessionsArgs<ExtArgs> = {}>(args?: Subset<T, User$sessionsArgs<ExtArgs>>): Prisma.PrismaPromise<$Result.GetResult<Prisma.$UserSessionPayload<ExtArgs>, T, "findMany", GlobalOmitOptions> | Null>
    /**
     * Attaches callbacks for the resolution and/or rejection of the Promise.
     * @param onfulfilled The callback to execute when the Promise is resolved.
     * @param onrejected The callback to execute when the Promise is rejected.
     * @returns A Promise for the completion of which ever callback is executed.
     */
    then<TResult1 = T, TResult2 = never>(onfulfilled?: ((value: T) => TResult1 | PromiseLike<TResult1>) | undefined | null, onrejected?: ((reason: any) => TResult2 | PromiseLike<TResult2>) | undefined | null): $Utils.JsPromise<TResult1 | TResult2>
    /**
     * Attaches a callback for only the rejection of the Promise.
     * @param onrejected The callback to execute when the Promise is rejected.
     * @returns A Promise for the completion of the callback.
     */
    catch<TResult = never>(onrejected?: ((reason: any) => TResult | PromiseLike<TResult>) | undefined | null): $Utils.JsPromise<T | TResult>
    /**
     * Attaches a callback that is invoked when the Promise is settled (fulfilled or rejected). The
     * resolved value cannot be modified from the callback.
     * @param onfinally The callback to execute when the Promise is settled (fulfilled or rejected).
     * @returns A Promise for the completion of the callback.
     */
    finally(onfinally?: (() => void) | undefined | null): $Utils.JsPromise<T>
  }




  /**
   * Fields of the User model
   */
  interface UserFieldRefs {
    readonly id: FieldRef<"User", 'String'>
    readonly createdAt: FieldRef<"User", 'DateTime'>
    readonly updatedAt: FieldRef<"User", 'DateTime'>
    readonly firstName: FieldRef<"User", 'String'>
    readonly lastName: FieldRef<"User", 'String'>
    readonly email: FieldRef<"User", 'String'>
    readonly phoneNumber: FieldRef<"User", 'String'>
    readonly passwordHash: FieldRef<"User", 'String'>
    readonly role: FieldRef<"User", 'Role'>
    readonly status: FieldRef<"User", 'UserStatus'>
    readonly isPhoneVerified: FieldRef<"User", 'Boolean'>
    readonly pointsBalance: FieldRef<"User", 'Int'>
    readonly totalPointsEarned: FieldRef<"User", 'Int'>
    readonly totalPointsSpent: FieldRef<"User", 'Int'>
    readonly lastActiveAt: FieldRef<"User", 'DateTime'>
  }
    

  // Custom InputTypes
  /**
   * User findUnique
   */
  export type UserFindUniqueArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the User
     */
    select?: UserSelect<ExtArgs> | null
    /**
     * Omit specific fields from the User
     */
    omit?: UserOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: UserInclude<ExtArgs> | null
    /**
     * Filter, which User to fetch.
     */
    where: UserWhereUniqueInput
  }

  /**
   * User findUniqueOrThrow
   */
  export type UserFindUniqueOrThrowArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the User
     */
    select?: UserSelect<ExtArgs> | null
    /**
     * Omit specific fields from the User
     */
    omit?: UserOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: UserInclude<ExtArgs> | null
    /**
     * Filter, which User to fetch.
     */
    where: UserWhereUniqueInput
  }

  /**
   * User findFirst
   */
  export type UserFindFirstArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the User
     */
    select?: UserSelect<ExtArgs> | null
    /**
     * Omit specific fields from the User
     */
    omit?: UserOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: UserInclude<ExtArgs> | null
    /**
     * Filter, which User to fetch.
     */
    where?: UserWhereInput
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/sorting Sorting Docs}
     * 
     * Determine the order of Users to fetch.
     */
    orderBy?: UserOrderByWithRelationInput | UserOrderByWithRelationInput[]
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination#cursor-based-pagination Cursor Docs}
     * 
     * Sets the position for searching for Users.
     */
    cursor?: UserWhereUniqueInput
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination Pagination Docs}
     * 
     * Take `±n` Users from the position of the cursor.
     */
    take?: number
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination Pagination Docs}
     * 
     * Skip the first `n` Users.
     */
    skip?: number
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/distinct Distinct Docs}
     * 
     * Filter by unique combinations of Users.
     */
    distinct?: UserScalarFieldEnum | UserScalarFieldEnum[]
  }

  /**
   * User findFirstOrThrow
   */
  export type UserFindFirstOrThrowArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the User
     */
    select?: UserSelect<ExtArgs> | null
    /**
     * Omit specific fields from the User
     */
    omit?: UserOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: UserInclude<ExtArgs> | null
    /**
     * Filter, which User to fetch.
     */
    where?: UserWhereInput
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/sorting Sorting Docs}
     * 
     * Determine the order of Users to fetch.
     */
    orderBy?: UserOrderByWithRelationInput | UserOrderByWithRelationInput[]
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination#cursor-based-pagination Cursor Docs}
     * 
     * Sets the position for searching for Users.
     */
    cursor?: UserWhereUniqueInput
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination Pagination Docs}
     * 
     * Take `±n` Users from the position of the cursor.
     */
    take?: number
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination Pagination Docs}
     * 
     * Skip the first `n` Users.
     */
    skip?: number
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/distinct Distinct Docs}
     * 
     * Filter by unique combinations of Users.
     */
    distinct?: UserScalarFieldEnum | UserScalarFieldEnum[]
  }

  /**
   * User findMany
   */
  export type UserFindManyArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the User
     */
    select?: UserSelect<ExtArgs> | null
    /**
     * Omit specific fields from the User
     */
    omit?: UserOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: UserInclude<ExtArgs> | null
    /**
     * Filter, which Users to fetch.
     */
    where?: UserWhereInput
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/sorting Sorting Docs}
     * 
     * Determine the order of Users to fetch.
     */
    orderBy?: UserOrderByWithRelationInput | UserOrderByWithRelationInput[]
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination#cursor-based-pagination Cursor Docs}
     * 
     * Sets the position for listing Users.
     */
    cursor?: UserWhereUniqueInput
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination Pagination Docs}
     * 
     * Take `±n` Users from the position of the cursor.
     */
    take?: number
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination Pagination Docs}
     * 
     * Skip the first `n` Users.
     */
    skip?: number
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/distinct Distinct Docs}
     * 
     * Filter by unique combinations of Users.
     */
    distinct?: UserScalarFieldEnum | UserScalarFieldEnum[]
  }

  /**
   * User create
   */
  export type UserCreateArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the User
     */
    select?: UserSelect<ExtArgs> | null
    /**
     * Omit specific fields from the User
     */
    omit?: UserOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: UserInclude<ExtArgs> | null
    /**
     * The data needed to create a User.
     */
    data: XOR<UserCreateInput, UserUncheckedCreateInput>
  }

  /**
   * User createMany
   */
  export type UserCreateManyArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * The data used to create many Users.
     */
    data: UserCreateManyInput | UserCreateManyInput[]
    skipDuplicates?: boolean
  }

  /**
   * User createManyAndReturn
   */
  export type UserCreateManyAndReturnArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the User
     */
    select?: UserSelectCreateManyAndReturn<ExtArgs> | null
    /**
     * Omit specific fields from the User
     */
    omit?: UserOmit<ExtArgs> | null
    /**
     * The data used to create many Users.
     */
    data: UserCreateManyInput | UserCreateManyInput[]
    skipDuplicates?: boolean
  }

  /**
   * User update
   */
  export type UserUpdateArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the User
     */
    select?: UserSelect<ExtArgs> | null
    /**
     * Omit specific fields from the User
     */
    omit?: UserOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: UserInclude<ExtArgs> | null
    /**
     * The data needed to update a User.
     */
    data: XOR<UserUpdateInput, UserUncheckedUpdateInput>
    /**
     * Choose, which User to update.
     */
    where: UserWhereUniqueInput
  }

  /**
   * User updateMany
   */
  export type UserUpdateManyArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * The data used to update Users.
     */
    data: XOR<UserUpdateManyMutationInput, UserUncheckedUpdateManyInput>
    /**
     * Filter which Users to update
     */
    where?: UserWhereInput
    /**
     * Limit how many Users to update.
     */
    limit?: number
  }

  /**
   * User updateManyAndReturn
   */
  export type UserUpdateManyAndReturnArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the User
     */
    select?: UserSelectUpdateManyAndReturn<ExtArgs> | null
    /**
     * Omit specific fields from the User
     */
    omit?: UserOmit<ExtArgs> | null
    /**
     * The data used to update Users.
     */
    data: XOR<UserUpdateManyMutationInput, UserUncheckedUpdateManyInput>
    /**
     * Filter which Users to update
     */
    where?: UserWhereInput
    /**
     * Limit how many Users to update.
     */
    limit?: number
  }

  /**
   * User upsert
   */
  export type UserUpsertArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the User
     */
    select?: UserSelect<ExtArgs> | null
    /**
     * Omit specific fields from the User
     */
    omit?: UserOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: UserInclude<ExtArgs> | null
    /**
     * The filter to search for the User to update in case it exists.
     */
    where: UserWhereUniqueInput
    /**
     * In case the User found by the `where` argument doesn't exist, create a new User with this data.
     */
    create: XOR<UserCreateInput, UserUncheckedCreateInput>
    /**
     * In case the User was found with the provided `where` argument, update it with this data.
     */
    update: XOR<UserUpdateInput, UserUncheckedUpdateInput>
  }

  /**
   * User delete
   */
  export type UserDeleteArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the User
     */
    select?: UserSelect<ExtArgs> | null
    /**
     * Omit specific fields from the User
     */
    omit?: UserOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: UserInclude<ExtArgs> | null
    /**
     * Filter which User to delete.
     */
    where: UserWhereUniqueInput
  }

  /**
   * User deleteMany
   */
  export type UserDeleteManyArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Filter which Users to delete
     */
    where?: UserWhereInput
    /**
     * Limit how many Users to delete.
     */
    limit?: number
  }

  /**
   * User.reports
   */
  export type User$reportsArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the Report
     */
    select?: ReportSelect<ExtArgs> | null
    /**
     * Omit specific fields from the Report
     */
    omit?: ReportOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: ReportInclude<ExtArgs> | null
    where?: ReportWhereInput
    orderBy?: ReportOrderByWithRelationInput | ReportOrderByWithRelationInput[]
    cursor?: ReportWhereUniqueInput
    take?: number
    skip?: number
    distinct?: ReportScalarFieldEnum | ReportScalarFieldEnum[]
  }

  /**
   * User.moderatedReports
   */
  export type User$moderatedReportsArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the Report
     */
    select?: ReportSelect<ExtArgs> | null
    /**
     * Omit specific fields from the Report
     */
    omit?: ReportOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: ReportInclude<ExtArgs> | null
    where?: ReportWhereInput
    orderBy?: ReportOrderByWithRelationInput | ReportOrderByWithRelationInput[]
    cursor?: ReportWhereUniqueInput
    take?: number
    skip?: number
    distinct?: ReportScalarFieldEnum | ReportScalarFieldEnum[]
  }

  /**
   * User.adminNotifications
   */
  export type User$adminNotificationsArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the AdminNotification
     */
    select?: AdminNotificationSelect<ExtArgs> | null
    /**
     * Omit specific fields from the AdminNotification
     */
    omit?: AdminNotificationOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: AdminNotificationInclude<ExtArgs> | null
    where?: AdminNotificationWhereInput
    orderBy?: AdminNotificationOrderByWithRelationInput | AdminNotificationOrderByWithRelationInput[]
    cursor?: AdminNotificationWhereUniqueInput
    take?: number
    skip?: number
    distinct?: AdminNotificationScalarFieldEnum | AdminNotificationScalarFieldEnum[]
  }

  /**
   * User.pointTransactions
   */
  export type User$pointTransactionsArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the PointTransaction
     */
    select?: PointTransactionSelect<ExtArgs> | null
    /**
     * Omit specific fields from the PointTransaction
     */
    omit?: PointTransactionOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: PointTransactionInclude<ExtArgs> | null
    where?: PointTransactionWhereInput
    orderBy?: PointTransactionOrderByWithRelationInput | PointTransactionOrderByWithRelationInput[]
    cursor?: PointTransactionWhereUniqueInput
    take?: number
    skip?: number
    distinct?: PointTransactionScalarFieldEnum | PointTransactionScalarFieldEnum[]
  }

  /**
   * User.coReportedReports
   */
  export type User$coReportedReportsArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the ReportCoReporter
     */
    select?: ReportCoReporterSelect<ExtArgs> | null
    /**
     * Omit specific fields from the ReportCoReporter
     */
    omit?: ReportCoReporterOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: ReportCoReporterInclude<ExtArgs> | null
    where?: ReportCoReporterWhereInput
    orderBy?: ReportCoReporterOrderByWithRelationInput | ReportCoReporterOrderByWithRelationInput[]
    cursor?: ReportCoReporterWhereUniqueInput
    take?: number
    skip?: number
    distinct?: ReportCoReporterScalarFieldEnum | ReportCoReporterScalarFieldEnum[]
  }

  /**
   * User.sessions
   */
  export type User$sessionsArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the UserSession
     */
    select?: UserSessionSelect<ExtArgs> | null
    /**
     * Omit specific fields from the UserSession
     */
    omit?: UserSessionOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: UserSessionInclude<ExtArgs> | null
    where?: UserSessionWhereInput
    orderBy?: UserSessionOrderByWithRelationInput | UserSessionOrderByWithRelationInput[]
    cursor?: UserSessionWhereUniqueInput
    take?: number
    skip?: number
    distinct?: UserSessionScalarFieldEnum | UserSessionScalarFieldEnum[]
  }

  /**
   * User without action
   */
  export type UserDefaultArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the User
     */
    select?: UserSelect<ExtArgs> | null
    /**
     * Omit specific fields from the User
     */
    omit?: UserOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: UserInclude<ExtArgs> | null
  }


  /**
   * Model UserSession
   */

  export type AggregateUserSession = {
    _count: UserSessionCountAggregateOutputType | null
    _min: UserSessionMinAggregateOutputType | null
    _max: UserSessionMaxAggregateOutputType | null
  }

  export type UserSessionMinAggregateOutputType = {
    id: string | null
    createdAt: Date | null
    userId: string | null
    tokenId: string | null
    refreshTokenHash: string | null
    deviceInfo: string | null
    ipAddress: string | null
    expiresAt: Date | null
    revokedAt: Date | null
  }

  export type UserSessionMaxAggregateOutputType = {
    id: string | null
    createdAt: Date | null
    userId: string | null
    tokenId: string | null
    refreshTokenHash: string | null
    deviceInfo: string | null
    ipAddress: string | null
    expiresAt: Date | null
    revokedAt: Date | null
  }

  export type UserSessionCountAggregateOutputType = {
    id: number
    createdAt: number
    userId: number
    tokenId: number
    refreshTokenHash: number
    deviceInfo: number
    ipAddress: number
    expiresAt: number
    revokedAt: number
    _all: number
  }


  export type UserSessionMinAggregateInputType = {
    id?: true
    createdAt?: true
    userId?: true
    tokenId?: true
    refreshTokenHash?: true
    deviceInfo?: true
    ipAddress?: true
    expiresAt?: true
    revokedAt?: true
  }

  export type UserSessionMaxAggregateInputType = {
    id?: true
    createdAt?: true
    userId?: true
    tokenId?: true
    refreshTokenHash?: true
    deviceInfo?: true
    ipAddress?: true
    expiresAt?: true
    revokedAt?: true
  }

  export type UserSessionCountAggregateInputType = {
    id?: true
    createdAt?: true
    userId?: true
    tokenId?: true
    refreshTokenHash?: true
    deviceInfo?: true
    ipAddress?: true
    expiresAt?: true
    revokedAt?: true
    _all?: true
  }

  export type UserSessionAggregateArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Filter which UserSession to aggregate.
     */
    where?: UserSessionWhereInput
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/sorting Sorting Docs}
     * 
     * Determine the order of UserSessions to fetch.
     */
    orderBy?: UserSessionOrderByWithRelationInput | UserSessionOrderByWithRelationInput[]
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination#cursor-based-pagination Cursor Docs}
     * 
     * Sets the start position
     */
    cursor?: UserSessionWhereUniqueInput
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination Pagination Docs}
     * 
     * Take `±n` UserSessions from the position of the cursor.
     */
    take?: number
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination Pagination Docs}
     * 
     * Skip the first `n` UserSessions.
     */
    skip?: number
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/aggregations Aggregation Docs}
     * 
     * Count returned UserSessions
    **/
    _count?: true | UserSessionCountAggregateInputType
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/aggregations Aggregation Docs}
     * 
     * Select which fields to find the minimum value
    **/
    _min?: UserSessionMinAggregateInputType
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/aggregations Aggregation Docs}
     * 
     * Select which fields to find the maximum value
    **/
    _max?: UserSessionMaxAggregateInputType
  }

  export type GetUserSessionAggregateType<T extends UserSessionAggregateArgs> = {
        [P in keyof T & keyof AggregateUserSession]: P extends '_count' | 'count'
      ? T[P] extends true
        ? number
        : GetScalarType<T[P], AggregateUserSession[P]>
      : GetScalarType<T[P], AggregateUserSession[P]>
  }




  export type UserSessionGroupByArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    where?: UserSessionWhereInput
    orderBy?: UserSessionOrderByWithAggregationInput | UserSessionOrderByWithAggregationInput[]
    by: UserSessionScalarFieldEnum[] | UserSessionScalarFieldEnum
    having?: UserSessionScalarWhereWithAggregatesInput
    take?: number
    skip?: number
    _count?: UserSessionCountAggregateInputType | true
    _min?: UserSessionMinAggregateInputType
    _max?: UserSessionMaxAggregateInputType
  }

  export type UserSessionGroupByOutputType = {
    id: string
    createdAt: Date
    userId: string
    tokenId: string
    refreshTokenHash: string
    deviceInfo: string | null
    ipAddress: string | null
    expiresAt: Date
    revokedAt: Date | null
    _count: UserSessionCountAggregateOutputType | null
    _min: UserSessionMinAggregateOutputType | null
    _max: UserSessionMaxAggregateOutputType | null
  }

  type GetUserSessionGroupByPayload<T extends UserSessionGroupByArgs> = Prisma.PrismaPromise<
    Array<
      PickEnumerable<UserSessionGroupByOutputType, T['by']> &
        {
          [P in ((keyof T) & (keyof UserSessionGroupByOutputType))]: P extends '_count'
            ? T[P] extends boolean
              ? number
              : GetScalarType<T[P], UserSessionGroupByOutputType[P]>
            : GetScalarType<T[P], UserSessionGroupByOutputType[P]>
        }
      >
    >


  export type UserSessionSelect<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = $Extensions.GetSelect<{
    id?: boolean
    createdAt?: boolean
    userId?: boolean
    tokenId?: boolean
    refreshTokenHash?: boolean
    deviceInfo?: boolean
    ipAddress?: boolean
    expiresAt?: boolean
    revokedAt?: boolean
    user?: boolean | UserDefaultArgs<ExtArgs>
  }, ExtArgs["result"]["userSession"]>

  export type UserSessionSelectCreateManyAndReturn<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = $Extensions.GetSelect<{
    id?: boolean
    createdAt?: boolean
    userId?: boolean
    tokenId?: boolean
    refreshTokenHash?: boolean
    deviceInfo?: boolean
    ipAddress?: boolean
    expiresAt?: boolean
    revokedAt?: boolean
    user?: boolean | UserDefaultArgs<ExtArgs>
  }, ExtArgs["result"]["userSession"]>

  export type UserSessionSelectUpdateManyAndReturn<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = $Extensions.GetSelect<{
    id?: boolean
    createdAt?: boolean
    userId?: boolean
    tokenId?: boolean
    refreshTokenHash?: boolean
    deviceInfo?: boolean
    ipAddress?: boolean
    expiresAt?: boolean
    revokedAt?: boolean
    user?: boolean | UserDefaultArgs<ExtArgs>
  }, ExtArgs["result"]["userSession"]>

  export type UserSessionSelectScalar = {
    id?: boolean
    createdAt?: boolean
    userId?: boolean
    tokenId?: boolean
    refreshTokenHash?: boolean
    deviceInfo?: boolean
    ipAddress?: boolean
    expiresAt?: boolean
    revokedAt?: boolean
  }

  export type UserSessionOmit<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = $Extensions.GetOmit<"id" | "createdAt" | "userId" | "tokenId" | "refreshTokenHash" | "deviceInfo" | "ipAddress" | "expiresAt" | "revokedAt", ExtArgs["result"]["userSession"]>
  export type UserSessionInclude<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    user?: boolean | UserDefaultArgs<ExtArgs>
  }
  export type UserSessionIncludeCreateManyAndReturn<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    user?: boolean | UserDefaultArgs<ExtArgs>
  }
  export type UserSessionIncludeUpdateManyAndReturn<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    user?: boolean | UserDefaultArgs<ExtArgs>
  }

  export type $UserSessionPayload<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    name: "UserSession"
    objects: {
      user: Prisma.$UserPayload<ExtArgs>
    }
    scalars: $Extensions.GetPayloadResult<{
      id: string
      createdAt: Date
      userId: string
      tokenId: string
      refreshTokenHash: string
      deviceInfo: string | null
      ipAddress: string | null
      expiresAt: Date
      revokedAt: Date | null
    }, ExtArgs["result"]["userSession"]>
    composites: {}
  }

  type UserSessionGetPayload<S extends boolean | null | undefined | UserSessionDefaultArgs> = $Result.GetResult<Prisma.$UserSessionPayload, S>

  type UserSessionCountArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> =
    Omit<UserSessionFindManyArgs, 'select' | 'include' | 'distinct' | 'omit'> & {
      select?: UserSessionCountAggregateInputType | true
    }

  export interface UserSessionDelegate<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs, GlobalOmitOptions = {}> {
    [K: symbol]: { types: Prisma.TypeMap<ExtArgs>['model']['UserSession'], meta: { name: 'UserSession' } }
    /**
     * Find zero or one UserSession that matches the filter.
     * @param {UserSessionFindUniqueArgs} args - Arguments to find a UserSession
     * @example
     * // Get one UserSession
     * const userSession = await prisma.userSession.findUnique({
     *   where: {
     *     // ... provide filter here
     *   }
     * })
     */
    findUnique<T extends UserSessionFindUniqueArgs>(args: SelectSubset<T, UserSessionFindUniqueArgs<ExtArgs>>): Prisma__UserSessionClient<$Result.GetResult<Prisma.$UserSessionPayload<ExtArgs>, T, "findUnique", GlobalOmitOptions> | null, null, ExtArgs, GlobalOmitOptions>

    /**
     * Find one UserSession that matches the filter or throw an error with `error.code='P2025'`
     * if no matches were found.
     * @param {UserSessionFindUniqueOrThrowArgs} args - Arguments to find a UserSession
     * @example
     * // Get one UserSession
     * const userSession = await prisma.userSession.findUniqueOrThrow({
     *   where: {
     *     // ... provide filter here
     *   }
     * })
     */
    findUniqueOrThrow<T extends UserSessionFindUniqueOrThrowArgs>(args: SelectSubset<T, UserSessionFindUniqueOrThrowArgs<ExtArgs>>): Prisma__UserSessionClient<$Result.GetResult<Prisma.$UserSessionPayload<ExtArgs>, T, "findUniqueOrThrow", GlobalOmitOptions>, never, ExtArgs, GlobalOmitOptions>

    /**
     * Find the first UserSession that matches the filter.
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * @param {UserSessionFindFirstArgs} args - Arguments to find a UserSession
     * @example
     * // Get one UserSession
     * const userSession = await prisma.userSession.findFirst({
     *   where: {
     *     // ... provide filter here
     *   }
     * })
     */
    findFirst<T extends UserSessionFindFirstArgs>(args?: SelectSubset<T, UserSessionFindFirstArgs<ExtArgs>>): Prisma__UserSessionClient<$Result.GetResult<Prisma.$UserSessionPayload<ExtArgs>, T, "findFirst", GlobalOmitOptions> | null, null, ExtArgs, GlobalOmitOptions>

    /**
     * Find the first UserSession that matches the filter or
     * throw `PrismaKnownClientError` with `P2025` code if no matches were found.
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * @param {UserSessionFindFirstOrThrowArgs} args - Arguments to find a UserSession
     * @example
     * // Get one UserSession
     * const userSession = await prisma.userSession.findFirstOrThrow({
     *   where: {
     *     // ... provide filter here
     *   }
     * })
     */
    findFirstOrThrow<T extends UserSessionFindFirstOrThrowArgs>(args?: SelectSubset<T, UserSessionFindFirstOrThrowArgs<ExtArgs>>): Prisma__UserSessionClient<$Result.GetResult<Prisma.$UserSessionPayload<ExtArgs>, T, "findFirstOrThrow", GlobalOmitOptions>, never, ExtArgs, GlobalOmitOptions>

    /**
     * Find zero or more UserSessions that matches the filter.
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * @param {UserSessionFindManyArgs} args - Arguments to filter and select certain fields only.
     * @example
     * // Get all UserSessions
     * const userSessions = await prisma.userSession.findMany()
     * 
     * // Get first 10 UserSessions
     * const userSessions = await prisma.userSession.findMany({ take: 10 })
     * 
     * // Only select the `id`
     * const userSessionWithIdOnly = await prisma.userSession.findMany({ select: { id: true } })
     * 
     */
    findMany<T extends UserSessionFindManyArgs>(args?: SelectSubset<T, UserSessionFindManyArgs<ExtArgs>>): Prisma.PrismaPromise<$Result.GetResult<Prisma.$UserSessionPayload<ExtArgs>, T, "findMany", GlobalOmitOptions>>

    /**
     * Create a UserSession.
     * @param {UserSessionCreateArgs} args - Arguments to create a UserSession.
     * @example
     * // Create one UserSession
     * const UserSession = await prisma.userSession.create({
     *   data: {
     *     // ... data to create a UserSession
     *   }
     * })
     * 
     */
    create<T extends UserSessionCreateArgs>(args: SelectSubset<T, UserSessionCreateArgs<ExtArgs>>): Prisma__UserSessionClient<$Result.GetResult<Prisma.$UserSessionPayload<ExtArgs>, T, "create", GlobalOmitOptions>, never, ExtArgs, GlobalOmitOptions>

    /**
     * Create many UserSessions.
     * @param {UserSessionCreateManyArgs} args - Arguments to create many UserSessions.
     * @example
     * // Create many UserSessions
     * const userSession = await prisma.userSession.createMany({
     *   data: [
     *     // ... provide data here
     *   ]
     * })
     *     
     */
    createMany<T extends UserSessionCreateManyArgs>(args?: SelectSubset<T, UserSessionCreateManyArgs<ExtArgs>>): Prisma.PrismaPromise<BatchPayload>

    /**
     * Create many UserSessions and returns the data saved in the database.
     * @param {UserSessionCreateManyAndReturnArgs} args - Arguments to create many UserSessions.
     * @example
     * // Create many UserSessions
     * const userSession = await prisma.userSession.createManyAndReturn({
     *   data: [
     *     // ... provide data here
     *   ]
     * })
     * 
     * // Create many UserSessions and only return the `id`
     * const userSessionWithIdOnly = await prisma.userSession.createManyAndReturn({
     *   select: { id: true },
     *   data: [
     *     // ... provide data here
     *   ]
     * })
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * 
     */
    createManyAndReturn<T extends UserSessionCreateManyAndReturnArgs>(args?: SelectSubset<T, UserSessionCreateManyAndReturnArgs<ExtArgs>>): Prisma.PrismaPromise<$Result.GetResult<Prisma.$UserSessionPayload<ExtArgs>, T, "createManyAndReturn", GlobalOmitOptions>>

    /**
     * Delete a UserSession.
     * @param {UserSessionDeleteArgs} args - Arguments to delete one UserSession.
     * @example
     * // Delete one UserSession
     * const UserSession = await prisma.userSession.delete({
     *   where: {
     *     // ... filter to delete one UserSession
     *   }
     * })
     * 
     */
    delete<T extends UserSessionDeleteArgs>(args: SelectSubset<T, UserSessionDeleteArgs<ExtArgs>>): Prisma__UserSessionClient<$Result.GetResult<Prisma.$UserSessionPayload<ExtArgs>, T, "delete", GlobalOmitOptions>, never, ExtArgs, GlobalOmitOptions>

    /**
     * Update one UserSession.
     * @param {UserSessionUpdateArgs} args - Arguments to update one UserSession.
     * @example
     * // Update one UserSession
     * const userSession = await prisma.userSession.update({
     *   where: {
     *     // ... provide filter here
     *   },
     *   data: {
     *     // ... provide data here
     *   }
     * })
     * 
     */
    update<T extends UserSessionUpdateArgs>(args: SelectSubset<T, UserSessionUpdateArgs<ExtArgs>>): Prisma__UserSessionClient<$Result.GetResult<Prisma.$UserSessionPayload<ExtArgs>, T, "update", GlobalOmitOptions>, never, ExtArgs, GlobalOmitOptions>

    /**
     * Delete zero or more UserSessions.
     * @param {UserSessionDeleteManyArgs} args - Arguments to filter UserSessions to delete.
     * @example
     * // Delete a few UserSessions
     * const { count } = await prisma.userSession.deleteMany({
     *   where: {
     *     // ... provide filter here
     *   }
     * })
     * 
     */
    deleteMany<T extends UserSessionDeleteManyArgs>(args?: SelectSubset<T, UserSessionDeleteManyArgs<ExtArgs>>): Prisma.PrismaPromise<BatchPayload>

    /**
     * Update zero or more UserSessions.
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * @param {UserSessionUpdateManyArgs} args - Arguments to update one or more rows.
     * @example
     * // Update many UserSessions
     * const userSession = await prisma.userSession.updateMany({
     *   where: {
     *     // ... provide filter here
     *   },
     *   data: {
     *     // ... provide data here
     *   }
     * })
     * 
     */
    updateMany<T extends UserSessionUpdateManyArgs>(args: SelectSubset<T, UserSessionUpdateManyArgs<ExtArgs>>): Prisma.PrismaPromise<BatchPayload>

    /**
     * Update zero or more UserSessions and returns the data updated in the database.
     * @param {UserSessionUpdateManyAndReturnArgs} args - Arguments to update many UserSessions.
     * @example
     * // Update many UserSessions
     * const userSession = await prisma.userSession.updateManyAndReturn({
     *   where: {
     *     // ... provide filter here
     *   },
     *   data: [
     *     // ... provide data here
     *   ]
     * })
     * 
     * // Update zero or more UserSessions and only return the `id`
     * const userSessionWithIdOnly = await prisma.userSession.updateManyAndReturn({
     *   select: { id: true },
     *   where: {
     *     // ... provide filter here
     *   },
     *   data: [
     *     // ... provide data here
     *   ]
     * })
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * 
     */
    updateManyAndReturn<T extends UserSessionUpdateManyAndReturnArgs>(args: SelectSubset<T, UserSessionUpdateManyAndReturnArgs<ExtArgs>>): Prisma.PrismaPromise<$Result.GetResult<Prisma.$UserSessionPayload<ExtArgs>, T, "updateManyAndReturn", GlobalOmitOptions>>

    /**
     * Create or update one UserSession.
     * @param {UserSessionUpsertArgs} args - Arguments to update or create a UserSession.
     * @example
     * // Update or create a UserSession
     * const userSession = await prisma.userSession.upsert({
     *   create: {
     *     // ... data to create a UserSession
     *   },
     *   update: {
     *     // ... in case it already exists, update
     *   },
     *   where: {
     *     // ... the filter for the UserSession we want to update
     *   }
     * })
     */
    upsert<T extends UserSessionUpsertArgs>(args: SelectSubset<T, UserSessionUpsertArgs<ExtArgs>>): Prisma__UserSessionClient<$Result.GetResult<Prisma.$UserSessionPayload<ExtArgs>, T, "upsert", GlobalOmitOptions>, never, ExtArgs, GlobalOmitOptions>


    /**
     * Count the number of UserSessions.
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * @param {UserSessionCountArgs} args - Arguments to filter UserSessions to count.
     * @example
     * // Count the number of UserSessions
     * const count = await prisma.userSession.count({
     *   where: {
     *     // ... the filter for the UserSessions we want to count
     *   }
     * })
    **/
    count<T extends UserSessionCountArgs>(
      args?: Subset<T, UserSessionCountArgs>,
    ): Prisma.PrismaPromise<
      T extends $Utils.Record<'select', any>
        ? T['select'] extends true
          ? number
          : GetScalarType<T['select'], UserSessionCountAggregateOutputType>
        : number
    >

    /**
     * Allows you to perform aggregations operations on a UserSession.
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * @param {UserSessionAggregateArgs} args - Select which aggregations you would like to apply and on what fields.
     * @example
     * // Ordered by age ascending
     * // Where email contains prisma.io
     * // Limited to the 10 users
     * const aggregations = await prisma.user.aggregate({
     *   _avg: {
     *     age: true,
     *   },
     *   where: {
     *     email: {
     *       contains: "prisma.io",
     *     },
     *   },
     *   orderBy: {
     *     age: "asc",
     *   },
     *   take: 10,
     * })
    **/
    aggregate<T extends UserSessionAggregateArgs>(args: Subset<T, UserSessionAggregateArgs>): Prisma.PrismaPromise<GetUserSessionAggregateType<T>>

    /**
     * Group by UserSession.
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * @param {UserSessionGroupByArgs} args - Group by arguments.
     * @example
     * // Group by city, order by createdAt, get count
     * const result = await prisma.user.groupBy({
     *   by: ['city', 'createdAt'],
     *   orderBy: {
     *     createdAt: true
     *   },
     *   _count: {
     *     _all: true
     *   },
     * })
     * 
    **/
    groupBy<
      T extends UserSessionGroupByArgs,
      HasSelectOrTake extends Or<
        Extends<'skip', Keys<T>>,
        Extends<'take', Keys<T>>
      >,
      OrderByArg extends True extends HasSelectOrTake
        ? { orderBy: UserSessionGroupByArgs['orderBy'] }
        : { orderBy?: UserSessionGroupByArgs['orderBy'] },
      OrderFields extends ExcludeUnderscoreKeys<Keys<MaybeTupleToUnion<T['orderBy']>>>,
      ByFields extends MaybeTupleToUnion<T['by']>,
      ByValid extends Has<ByFields, OrderFields>,
      HavingFields extends GetHavingFields<T['having']>,
      HavingValid extends Has<ByFields, HavingFields>,
      ByEmpty extends T['by'] extends never[] ? True : False,
      InputErrors extends ByEmpty extends True
      ? `Error: "by" must not be empty.`
      : HavingValid extends False
      ? {
          [P in HavingFields]: P extends ByFields
            ? never
            : P extends string
            ? `Error: Field "${P}" used in "having" needs to be provided in "by".`
            : [
                Error,
                'Field ',
                P,
                ` in "having" needs to be provided in "by"`,
              ]
        }[HavingFields]
      : 'take' extends Keys<T>
      ? 'orderBy' extends Keys<T>
        ? ByValid extends True
          ? {}
          : {
              [P in OrderFields]: P extends ByFields
                ? never
                : `Error: Field "${P}" in "orderBy" needs to be provided in "by"`
            }[OrderFields]
        : 'Error: If you provide "take", you also need to provide "orderBy"'
      : 'skip' extends Keys<T>
      ? 'orderBy' extends Keys<T>
        ? ByValid extends True
          ? {}
          : {
              [P in OrderFields]: P extends ByFields
                ? never
                : `Error: Field "${P}" in "orderBy" needs to be provided in "by"`
            }[OrderFields]
        : 'Error: If you provide "skip", you also need to provide "orderBy"'
      : ByValid extends True
      ? {}
      : {
          [P in OrderFields]: P extends ByFields
            ? never
            : `Error: Field "${P}" in "orderBy" needs to be provided in "by"`
        }[OrderFields]
    >(args: SubsetIntersection<T, UserSessionGroupByArgs, OrderByArg> & InputErrors): {} extends InputErrors ? GetUserSessionGroupByPayload<T> : Prisma.PrismaPromise<InputErrors>
  /**
   * Fields of the UserSession model
   */
  readonly fields: UserSessionFieldRefs;
  }

  /**
   * The delegate class that acts as a "Promise-like" for UserSession.
   * Why is this prefixed with `Prisma__`?
   * Because we want to prevent naming conflicts as mentioned in
   * https://github.com/prisma/prisma-client-js/issues/707
   */
  export interface Prisma__UserSessionClient<T, Null = never, ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs, GlobalOmitOptions = {}> extends Prisma.PrismaPromise<T> {
    readonly [Symbol.toStringTag]: "PrismaPromise"
    user<T extends UserDefaultArgs<ExtArgs> = {}>(args?: Subset<T, UserDefaultArgs<ExtArgs>>): Prisma__UserClient<$Result.GetResult<Prisma.$UserPayload<ExtArgs>, T, "findUniqueOrThrow", GlobalOmitOptions> | Null, Null, ExtArgs, GlobalOmitOptions>
    /**
     * Attaches callbacks for the resolution and/or rejection of the Promise.
     * @param onfulfilled The callback to execute when the Promise is resolved.
     * @param onrejected The callback to execute when the Promise is rejected.
     * @returns A Promise for the completion of which ever callback is executed.
     */
    then<TResult1 = T, TResult2 = never>(onfulfilled?: ((value: T) => TResult1 | PromiseLike<TResult1>) | undefined | null, onrejected?: ((reason: any) => TResult2 | PromiseLike<TResult2>) | undefined | null): $Utils.JsPromise<TResult1 | TResult2>
    /**
     * Attaches a callback for only the rejection of the Promise.
     * @param onrejected The callback to execute when the Promise is rejected.
     * @returns A Promise for the completion of the callback.
     */
    catch<TResult = never>(onrejected?: ((reason: any) => TResult | PromiseLike<TResult>) | undefined | null): $Utils.JsPromise<T | TResult>
    /**
     * Attaches a callback that is invoked when the Promise is settled (fulfilled or rejected). The
     * resolved value cannot be modified from the callback.
     * @param onfinally The callback to execute when the Promise is settled (fulfilled or rejected).
     * @returns A Promise for the completion of the callback.
     */
    finally(onfinally?: (() => void) | undefined | null): $Utils.JsPromise<T>
  }




  /**
   * Fields of the UserSession model
   */
  interface UserSessionFieldRefs {
    readonly id: FieldRef<"UserSession", 'String'>
    readonly createdAt: FieldRef<"UserSession", 'DateTime'>
    readonly userId: FieldRef<"UserSession", 'String'>
    readonly tokenId: FieldRef<"UserSession", 'String'>
    readonly refreshTokenHash: FieldRef<"UserSession", 'String'>
    readonly deviceInfo: FieldRef<"UserSession", 'String'>
    readonly ipAddress: FieldRef<"UserSession", 'String'>
    readonly expiresAt: FieldRef<"UserSession", 'DateTime'>
    readonly revokedAt: FieldRef<"UserSession", 'DateTime'>
  }
    

  // Custom InputTypes
  /**
   * UserSession findUnique
   */
  export type UserSessionFindUniqueArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the UserSession
     */
    select?: UserSessionSelect<ExtArgs> | null
    /**
     * Omit specific fields from the UserSession
     */
    omit?: UserSessionOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: UserSessionInclude<ExtArgs> | null
    /**
     * Filter, which UserSession to fetch.
     */
    where: UserSessionWhereUniqueInput
  }

  /**
   * UserSession findUniqueOrThrow
   */
  export type UserSessionFindUniqueOrThrowArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the UserSession
     */
    select?: UserSessionSelect<ExtArgs> | null
    /**
     * Omit specific fields from the UserSession
     */
    omit?: UserSessionOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: UserSessionInclude<ExtArgs> | null
    /**
     * Filter, which UserSession to fetch.
     */
    where: UserSessionWhereUniqueInput
  }

  /**
   * UserSession findFirst
   */
  export type UserSessionFindFirstArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the UserSession
     */
    select?: UserSessionSelect<ExtArgs> | null
    /**
     * Omit specific fields from the UserSession
     */
    omit?: UserSessionOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: UserSessionInclude<ExtArgs> | null
    /**
     * Filter, which UserSession to fetch.
     */
    where?: UserSessionWhereInput
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/sorting Sorting Docs}
     * 
     * Determine the order of UserSessions to fetch.
     */
    orderBy?: UserSessionOrderByWithRelationInput | UserSessionOrderByWithRelationInput[]
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination#cursor-based-pagination Cursor Docs}
     * 
     * Sets the position for searching for UserSessions.
     */
    cursor?: UserSessionWhereUniqueInput
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination Pagination Docs}
     * 
     * Take `±n` UserSessions from the position of the cursor.
     */
    take?: number
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination Pagination Docs}
     * 
     * Skip the first `n` UserSessions.
     */
    skip?: number
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/distinct Distinct Docs}
     * 
     * Filter by unique combinations of UserSessions.
     */
    distinct?: UserSessionScalarFieldEnum | UserSessionScalarFieldEnum[]
  }

  /**
   * UserSession findFirstOrThrow
   */
  export type UserSessionFindFirstOrThrowArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the UserSession
     */
    select?: UserSessionSelect<ExtArgs> | null
    /**
     * Omit specific fields from the UserSession
     */
    omit?: UserSessionOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: UserSessionInclude<ExtArgs> | null
    /**
     * Filter, which UserSession to fetch.
     */
    where?: UserSessionWhereInput
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/sorting Sorting Docs}
     * 
     * Determine the order of UserSessions to fetch.
     */
    orderBy?: UserSessionOrderByWithRelationInput | UserSessionOrderByWithRelationInput[]
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination#cursor-based-pagination Cursor Docs}
     * 
     * Sets the position for searching for UserSessions.
     */
    cursor?: UserSessionWhereUniqueInput
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination Pagination Docs}
     * 
     * Take `±n` UserSessions from the position of the cursor.
     */
    take?: number
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination Pagination Docs}
     * 
     * Skip the first `n` UserSessions.
     */
    skip?: number
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/distinct Distinct Docs}
     * 
     * Filter by unique combinations of UserSessions.
     */
    distinct?: UserSessionScalarFieldEnum | UserSessionScalarFieldEnum[]
  }

  /**
   * UserSession findMany
   */
  export type UserSessionFindManyArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the UserSession
     */
    select?: UserSessionSelect<ExtArgs> | null
    /**
     * Omit specific fields from the UserSession
     */
    omit?: UserSessionOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: UserSessionInclude<ExtArgs> | null
    /**
     * Filter, which UserSessions to fetch.
     */
    where?: UserSessionWhereInput
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/sorting Sorting Docs}
     * 
     * Determine the order of UserSessions to fetch.
     */
    orderBy?: UserSessionOrderByWithRelationInput | UserSessionOrderByWithRelationInput[]
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination#cursor-based-pagination Cursor Docs}
     * 
     * Sets the position for listing UserSessions.
     */
    cursor?: UserSessionWhereUniqueInput
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination Pagination Docs}
     * 
     * Take `±n` UserSessions from the position of the cursor.
     */
    take?: number
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination Pagination Docs}
     * 
     * Skip the first `n` UserSessions.
     */
    skip?: number
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/distinct Distinct Docs}
     * 
     * Filter by unique combinations of UserSessions.
     */
    distinct?: UserSessionScalarFieldEnum | UserSessionScalarFieldEnum[]
  }

  /**
   * UserSession create
   */
  export type UserSessionCreateArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the UserSession
     */
    select?: UserSessionSelect<ExtArgs> | null
    /**
     * Omit specific fields from the UserSession
     */
    omit?: UserSessionOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: UserSessionInclude<ExtArgs> | null
    /**
     * The data needed to create a UserSession.
     */
    data: XOR<UserSessionCreateInput, UserSessionUncheckedCreateInput>
  }

  /**
   * UserSession createMany
   */
  export type UserSessionCreateManyArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * The data used to create many UserSessions.
     */
    data: UserSessionCreateManyInput | UserSessionCreateManyInput[]
    skipDuplicates?: boolean
  }

  /**
   * UserSession createManyAndReturn
   */
  export type UserSessionCreateManyAndReturnArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the UserSession
     */
    select?: UserSessionSelectCreateManyAndReturn<ExtArgs> | null
    /**
     * Omit specific fields from the UserSession
     */
    omit?: UserSessionOmit<ExtArgs> | null
    /**
     * The data used to create many UserSessions.
     */
    data: UserSessionCreateManyInput | UserSessionCreateManyInput[]
    skipDuplicates?: boolean
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: UserSessionIncludeCreateManyAndReturn<ExtArgs> | null
  }

  /**
   * UserSession update
   */
  export type UserSessionUpdateArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the UserSession
     */
    select?: UserSessionSelect<ExtArgs> | null
    /**
     * Omit specific fields from the UserSession
     */
    omit?: UserSessionOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: UserSessionInclude<ExtArgs> | null
    /**
     * The data needed to update a UserSession.
     */
    data: XOR<UserSessionUpdateInput, UserSessionUncheckedUpdateInput>
    /**
     * Choose, which UserSession to update.
     */
    where: UserSessionWhereUniqueInput
  }

  /**
   * UserSession updateMany
   */
  export type UserSessionUpdateManyArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * The data used to update UserSessions.
     */
    data: XOR<UserSessionUpdateManyMutationInput, UserSessionUncheckedUpdateManyInput>
    /**
     * Filter which UserSessions to update
     */
    where?: UserSessionWhereInput
    /**
     * Limit how many UserSessions to update.
     */
    limit?: number
  }

  /**
   * UserSession updateManyAndReturn
   */
  export type UserSessionUpdateManyAndReturnArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the UserSession
     */
    select?: UserSessionSelectUpdateManyAndReturn<ExtArgs> | null
    /**
     * Omit specific fields from the UserSession
     */
    omit?: UserSessionOmit<ExtArgs> | null
    /**
     * The data used to update UserSessions.
     */
    data: XOR<UserSessionUpdateManyMutationInput, UserSessionUncheckedUpdateManyInput>
    /**
     * Filter which UserSessions to update
     */
    where?: UserSessionWhereInput
    /**
     * Limit how many UserSessions to update.
     */
    limit?: number
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: UserSessionIncludeUpdateManyAndReturn<ExtArgs> | null
  }

  /**
   * UserSession upsert
   */
  export type UserSessionUpsertArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the UserSession
     */
    select?: UserSessionSelect<ExtArgs> | null
    /**
     * Omit specific fields from the UserSession
     */
    omit?: UserSessionOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: UserSessionInclude<ExtArgs> | null
    /**
     * The filter to search for the UserSession to update in case it exists.
     */
    where: UserSessionWhereUniqueInput
    /**
     * In case the UserSession found by the `where` argument doesn't exist, create a new UserSession with this data.
     */
    create: XOR<UserSessionCreateInput, UserSessionUncheckedCreateInput>
    /**
     * In case the UserSession was found with the provided `where` argument, update it with this data.
     */
    update: XOR<UserSessionUpdateInput, UserSessionUncheckedUpdateInput>
  }

  /**
   * UserSession delete
   */
  export type UserSessionDeleteArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the UserSession
     */
    select?: UserSessionSelect<ExtArgs> | null
    /**
     * Omit specific fields from the UserSession
     */
    omit?: UserSessionOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: UserSessionInclude<ExtArgs> | null
    /**
     * Filter which UserSession to delete.
     */
    where: UserSessionWhereUniqueInput
  }

  /**
   * UserSession deleteMany
   */
  export type UserSessionDeleteManyArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Filter which UserSessions to delete
     */
    where?: UserSessionWhereInput
    /**
     * Limit how many UserSessions to delete.
     */
    limit?: number
  }

  /**
   * UserSession without action
   */
  export type UserSessionDefaultArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the UserSession
     */
    select?: UserSessionSelect<ExtArgs> | null
    /**
     * Omit specific fields from the UserSession
     */
    omit?: UserSessionOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: UserSessionInclude<ExtArgs> | null
  }


  /**
   * Model PhoneOtp
   */

  export type AggregatePhoneOtp = {
    _count: PhoneOtpCountAggregateOutputType | null
    _avg: PhoneOtpAvgAggregateOutputType | null
    _sum: PhoneOtpSumAggregateOutputType | null
    _min: PhoneOtpMinAggregateOutputType | null
    _max: PhoneOtpMaxAggregateOutputType | null
  }

  export type PhoneOtpAvgAggregateOutputType = {
    attemptCount: number | null
  }

  export type PhoneOtpSumAggregateOutputType = {
    attemptCount: number | null
  }

  export type PhoneOtpMinAggregateOutputType = {
    id: string | null
    createdAt: Date | null
    phoneNumber: string | null
    code: string | null
    expiresAt: Date | null
    attemptCount: number | null
  }

  export type PhoneOtpMaxAggregateOutputType = {
    id: string | null
    createdAt: Date | null
    phoneNumber: string | null
    code: string | null
    expiresAt: Date | null
    attemptCount: number | null
  }

  export type PhoneOtpCountAggregateOutputType = {
    id: number
    createdAt: number
    phoneNumber: number
    code: number
    expiresAt: number
    attemptCount: number
    _all: number
  }


  export type PhoneOtpAvgAggregateInputType = {
    attemptCount?: true
  }

  export type PhoneOtpSumAggregateInputType = {
    attemptCount?: true
  }

  export type PhoneOtpMinAggregateInputType = {
    id?: true
    createdAt?: true
    phoneNumber?: true
    code?: true
    expiresAt?: true
    attemptCount?: true
  }

  export type PhoneOtpMaxAggregateInputType = {
    id?: true
    createdAt?: true
    phoneNumber?: true
    code?: true
    expiresAt?: true
    attemptCount?: true
  }

  export type PhoneOtpCountAggregateInputType = {
    id?: true
    createdAt?: true
    phoneNumber?: true
    code?: true
    expiresAt?: true
    attemptCount?: true
    _all?: true
  }

  export type PhoneOtpAggregateArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Filter which PhoneOtp to aggregate.
     */
    where?: PhoneOtpWhereInput
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/sorting Sorting Docs}
     * 
     * Determine the order of PhoneOtps to fetch.
     */
    orderBy?: PhoneOtpOrderByWithRelationInput | PhoneOtpOrderByWithRelationInput[]
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination#cursor-based-pagination Cursor Docs}
     * 
     * Sets the start position
     */
    cursor?: PhoneOtpWhereUniqueInput
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination Pagination Docs}
     * 
     * Take `±n` PhoneOtps from the position of the cursor.
     */
    take?: number
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination Pagination Docs}
     * 
     * Skip the first `n` PhoneOtps.
     */
    skip?: number
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/aggregations Aggregation Docs}
     * 
     * Count returned PhoneOtps
    **/
    _count?: true | PhoneOtpCountAggregateInputType
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/aggregations Aggregation Docs}
     * 
     * Select which fields to average
    **/
    _avg?: PhoneOtpAvgAggregateInputType
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/aggregations Aggregation Docs}
     * 
     * Select which fields to sum
    **/
    _sum?: PhoneOtpSumAggregateInputType
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/aggregations Aggregation Docs}
     * 
     * Select which fields to find the minimum value
    **/
    _min?: PhoneOtpMinAggregateInputType
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/aggregations Aggregation Docs}
     * 
     * Select which fields to find the maximum value
    **/
    _max?: PhoneOtpMaxAggregateInputType
  }

  export type GetPhoneOtpAggregateType<T extends PhoneOtpAggregateArgs> = {
        [P in keyof T & keyof AggregatePhoneOtp]: P extends '_count' | 'count'
      ? T[P] extends true
        ? number
        : GetScalarType<T[P], AggregatePhoneOtp[P]>
      : GetScalarType<T[P], AggregatePhoneOtp[P]>
  }




  export type PhoneOtpGroupByArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    where?: PhoneOtpWhereInput
    orderBy?: PhoneOtpOrderByWithAggregationInput | PhoneOtpOrderByWithAggregationInput[]
    by: PhoneOtpScalarFieldEnum[] | PhoneOtpScalarFieldEnum
    having?: PhoneOtpScalarWhereWithAggregatesInput
    take?: number
    skip?: number
    _count?: PhoneOtpCountAggregateInputType | true
    _avg?: PhoneOtpAvgAggregateInputType
    _sum?: PhoneOtpSumAggregateInputType
    _min?: PhoneOtpMinAggregateInputType
    _max?: PhoneOtpMaxAggregateInputType
  }

  export type PhoneOtpGroupByOutputType = {
    id: string
    createdAt: Date
    phoneNumber: string
    code: string
    expiresAt: Date
    attemptCount: number
    _count: PhoneOtpCountAggregateOutputType | null
    _avg: PhoneOtpAvgAggregateOutputType | null
    _sum: PhoneOtpSumAggregateOutputType | null
    _min: PhoneOtpMinAggregateOutputType | null
    _max: PhoneOtpMaxAggregateOutputType | null
  }

  type GetPhoneOtpGroupByPayload<T extends PhoneOtpGroupByArgs> = Prisma.PrismaPromise<
    Array<
      PickEnumerable<PhoneOtpGroupByOutputType, T['by']> &
        {
          [P in ((keyof T) & (keyof PhoneOtpGroupByOutputType))]: P extends '_count'
            ? T[P] extends boolean
              ? number
              : GetScalarType<T[P], PhoneOtpGroupByOutputType[P]>
            : GetScalarType<T[P], PhoneOtpGroupByOutputType[P]>
        }
      >
    >


  export type PhoneOtpSelect<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = $Extensions.GetSelect<{
    id?: boolean
    createdAt?: boolean
    phoneNumber?: boolean
    code?: boolean
    expiresAt?: boolean
    attemptCount?: boolean
  }, ExtArgs["result"]["phoneOtp"]>

  export type PhoneOtpSelectCreateManyAndReturn<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = $Extensions.GetSelect<{
    id?: boolean
    createdAt?: boolean
    phoneNumber?: boolean
    code?: boolean
    expiresAt?: boolean
    attemptCount?: boolean
  }, ExtArgs["result"]["phoneOtp"]>

  export type PhoneOtpSelectUpdateManyAndReturn<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = $Extensions.GetSelect<{
    id?: boolean
    createdAt?: boolean
    phoneNumber?: boolean
    code?: boolean
    expiresAt?: boolean
    attemptCount?: boolean
  }, ExtArgs["result"]["phoneOtp"]>

  export type PhoneOtpSelectScalar = {
    id?: boolean
    createdAt?: boolean
    phoneNumber?: boolean
    code?: boolean
    expiresAt?: boolean
    attemptCount?: boolean
  }

  export type PhoneOtpOmit<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = $Extensions.GetOmit<"id" | "createdAt" | "phoneNumber" | "code" | "expiresAt" | "attemptCount", ExtArgs["result"]["phoneOtp"]>

  export type $PhoneOtpPayload<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    name: "PhoneOtp"
    objects: {}
    scalars: $Extensions.GetPayloadResult<{
      id: string
      createdAt: Date
      phoneNumber: string
      code: string
      expiresAt: Date
      attemptCount: number
    }, ExtArgs["result"]["phoneOtp"]>
    composites: {}
  }

  type PhoneOtpGetPayload<S extends boolean | null | undefined | PhoneOtpDefaultArgs> = $Result.GetResult<Prisma.$PhoneOtpPayload, S>

  type PhoneOtpCountArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> =
    Omit<PhoneOtpFindManyArgs, 'select' | 'include' | 'distinct' | 'omit'> & {
      select?: PhoneOtpCountAggregateInputType | true
    }

  export interface PhoneOtpDelegate<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs, GlobalOmitOptions = {}> {
    [K: symbol]: { types: Prisma.TypeMap<ExtArgs>['model']['PhoneOtp'], meta: { name: 'PhoneOtp' } }
    /**
     * Find zero or one PhoneOtp that matches the filter.
     * @param {PhoneOtpFindUniqueArgs} args - Arguments to find a PhoneOtp
     * @example
     * // Get one PhoneOtp
     * const phoneOtp = await prisma.phoneOtp.findUnique({
     *   where: {
     *     // ... provide filter here
     *   }
     * })
     */
    findUnique<T extends PhoneOtpFindUniqueArgs>(args: SelectSubset<T, PhoneOtpFindUniqueArgs<ExtArgs>>): Prisma__PhoneOtpClient<$Result.GetResult<Prisma.$PhoneOtpPayload<ExtArgs>, T, "findUnique", GlobalOmitOptions> | null, null, ExtArgs, GlobalOmitOptions>

    /**
     * Find one PhoneOtp that matches the filter or throw an error with `error.code='P2025'`
     * if no matches were found.
     * @param {PhoneOtpFindUniqueOrThrowArgs} args - Arguments to find a PhoneOtp
     * @example
     * // Get one PhoneOtp
     * const phoneOtp = await prisma.phoneOtp.findUniqueOrThrow({
     *   where: {
     *     // ... provide filter here
     *   }
     * })
     */
    findUniqueOrThrow<T extends PhoneOtpFindUniqueOrThrowArgs>(args: SelectSubset<T, PhoneOtpFindUniqueOrThrowArgs<ExtArgs>>): Prisma__PhoneOtpClient<$Result.GetResult<Prisma.$PhoneOtpPayload<ExtArgs>, T, "findUniqueOrThrow", GlobalOmitOptions>, never, ExtArgs, GlobalOmitOptions>

    /**
     * Find the first PhoneOtp that matches the filter.
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * @param {PhoneOtpFindFirstArgs} args - Arguments to find a PhoneOtp
     * @example
     * // Get one PhoneOtp
     * const phoneOtp = await prisma.phoneOtp.findFirst({
     *   where: {
     *     // ... provide filter here
     *   }
     * })
     */
    findFirst<T extends PhoneOtpFindFirstArgs>(args?: SelectSubset<T, PhoneOtpFindFirstArgs<ExtArgs>>): Prisma__PhoneOtpClient<$Result.GetResult<Prisma.$PhoneOtpPayload<ExtArgs>, T, "findFirst", GlobalOmitOptions> | null, null, ExtArgs, GlobalOmitOptions>

    /**
     * Find the first PhoneOtp that matches the filter or
     * throw `PrismaKnownClientError` with `P2025` code if no matches were found.
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * @param {PhoneOtpFindFirstOrThrowArgs} args - Arguments to find a PhoneOtp
     * @example
     * // Get one PhoneOtp
     * const phoneOtp = await prisma.phoneOtp.findFirstOrThrow({
     *   where: {
     *     // ... provide filter here
     *   }
     * })
     */
    findFirstOrThrow<T extends PhoneOtpFindFirstOrThrowArgs>(args?: SelectSubset<T, PhoneOtpFindFirstOrThrowArgs<ExtArgs>>): Prisma__PhoneOtpClient<$Result.GetResult<Prisma.$PhoneOtpPayload<ExtArgs>, T, "findFirstOrThrow", GlobalOmitOptions>, never, ExtArgs, GlobalOmitOptions>

    /**
     * Find zero or more PhoneOtps that matches the filter.
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * @param {PhoneOtpFindManyArgs} args - Arguments to filter and select certain fields only.
     * @example
     * // Get all PhoneOtps
     * const phoneOtps = await prisma.phoneOtp.findMany()
     * 
     * // Get first 10 PhoneOtps
     * const phoneOtps = await prisma.phoneOtp.findMany({ take: 10 })
     * 
     * // Only select the `id`
     * const phoneOtpWithIdOnly = await prisma.phoneOtp.findMany({ select: { id: true } })
     * 
     */
    findMany<T extends PhoneOtpFindManyArgs>(args?: SelectSubset<T, PhoneOtpFindManyArgs<ExtArgs>>): Prisma.PrismaPromise<$Result.GetResult<Prisma.$PhoneOtpPayload<ExtArgs>, T, "findMany", GlobalOmitOptions>>

    /**
     * Create a PhoneOtp.
     * @param {PhoneOtpCreateArgs} args - Arguments to create a PhoneOtp.
     * @example
     * // Create one PhoneOtp
     * const PhoneOtp = await prisma.phoneOtp.create({
     *   data: {
     *     // ... data to create a PhoneOtp
     *   }
     * })
     * 
     */
    create<T extends PhoneOtpCreateArgs>(args: SelectSubset<T, PhoneOtpCreateArgs<ExtArgs>>): Prisma__PhoneOtpClient<$Result.GetResult<Prisma.$PhoneOtpPayload<ExtArgs>, T, "create", GlobalOmitOptions>, never, ExtArgs, GlobalOmitOptions>

    /**
     * Create many PhoneOtps.
     * @param {PhoneOtpCreateManyArgs} args - Arguments to create many PhoneOtps.
     * @example
     * // Create many PhoneOtps
     * const phoneOtp = await prisma.phoneOtp.createMany({
     *   data: [
     *     // ... provide data here
     *   ]
     * })
     *     
     */
    createMany<T extends PhoneOtpCreateManyArgs>(args?: SelectSubset<T, PhoneOtpCreateManyArgs<ExtArgs>>): Prisma.PrismaPromise<BatchPayload>

    /**
     * Create many PhoneOtps and returns the data saved in the database.
     * @param {PhoneOtpCreateManyAndReturnArgs} args - Arguments to create many PhoneOtps.
     * @example
     * // Create many PhoneOtps
     * const phoneOtp = await prisma.phoneOtp.createManyAndReturn({
     *   data: [
     *     // ... provide data here
     *   ]
     * })
     * 
     * // Create many PhoneOtps and only return the `id`
     * const phoneOtpWithIdOnly = await prisma.phoneOtp.createManyAndReturn({
     *   select: { id: true },
     *   data: [
     *     // ... provide data here
     *   ]
     * })
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * 
     */
    createManyAndReturn<T extends PhoneOtpCreateManyAndReturnArgs>(args?: SelectSubset<T, PhoneOtpCreateManyAndReturnArgs<ExtArgs>>): Prisma.PrismaPromise<$Result.GetResult<Prisma.$PhoneOtpPayload<ExtArgs>, T, "createManyAndReturn", GlobalOmitOptions>>

    /**
     * Delete a PhoneOtp.
     * @param {PhoneOtpDeleteArgs} args - Arguments to delete one PhoneOtp.
     * @example
     * // Delete one PhoneOtp
     * const PhoneOtp = await prisma.phoneOtp.delete({
     *   where: {
     *     // ... filter to delete one PhoneOtp
     *   }
     * })
     * 
     */
    delete<T extends PhoneOtpDeleteArgs>(args: SelectSubset<T, PhoneOtpDeleteArgs<ExtArgs>>): Prisma__PhoneOtpClient<$Result.GetResult<Prisma.$PhoneOtpPayload<ExtArgs>, T, "delete", GlobalOmitOptions>, never, ExtArgs, GlobalOmitOptions>

    /**
     * Update one PhoneOtp.
     * @param {PhoneOtpUpdateArgs} args - Arguments to update one PhoneOtp.
     * @example
     * // Update one PhoneOtp
     * const phoneOtp = await prisma.phoneOtp.update({
     *   where: {
     *     // ... provide filter here
     *   },
     *   data: {
     *     // ... provide data here
     *   }
     * })
     * 
     */
    update<T extends PhoneOtpUpdateArgs>(args: SelectSubset<T, PhoneOtpUpdateArgs<ExtArgs>>): Prisma__PhoneOtpClient<$Result.GetResult<Prisma.$PhoneOtpPayload<ExtArgs>, T, "update", GlobalOmitOptions>, never, ExtArgs, GlobalOmitOptions>

    /**
     * Delete zero or more PhoneOtps.
     * @param {PhoneOtpDeleteManyArgs} args - Arguments to filter PhoneOtps to delete.
     * @example
     * // Delete a few PhoneOtps
     * const { count } = await prisma.phoneOtp.deleteMany({
     *   where: {
     *     // ... provide filter here
     *   }
     * })
     * 
     */
    deleteMany<T extends PhoneOtpDeleteManyArgs>(args?: SelectSubset<T, PhoneOtpDeleteManyArgs<ExtArgs>>): Prisma.PrismaPromise<BatchPayload>

    /**
     * Update zero or more PhoneOtps.
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * @param {PhoneOtpUpdateManyArgs} args - Arguments to update one or more rows.
     * @example
     * // Update many PhoneOtps
     * const phoneOtp = await prisma.phoneOtp.updateMany({
     *   where: {
     *     // ... provide filter here
     *   },
     *   data: {
     *     // ... provide data here
     *   }
     * })
     * 
     */
    updateMany<T extends PhoneOtpUpdateManyArgs>(args: SelectSubset<T, PhoneOtpUpdateManyArgs<ExtArgs>>): Prisma.PrismaPromise<BatchPayload>

    /**
     * Update zero or more PhoneOtps and returns the data updated in the database.
     * @param {PhoneOtpUpdateManyAndReturnArgs} args - Arguments to update many PhoneOtps.
     * @example
     * // Update many PhoneOtps
     * const phoneOtp = await prisma.phoneOtp.updateManyAndReturn({
     *   where: {
     *     // ... provide filter here
     *   },
     *   data: [
     *     // ... provide data here
     *   ]
     * })
     * 
     * // Update zero or more PhoneOtps and only return the `id`
     * const phoneOtpWithIdOnly = await prisma.phoneOtp.updateManyAndReturn({
     *   select: { id: true },
     *   where: {
     *     // ... provide filter here
     *   },
     *   data: [
     *     // ... provide data here
     *   ]
     * })
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * 
     */
    updateManyAndReturn<T extends PhoneOtpUpdateManyAndReturnArgs>(args: SelectSubset<T, PhoneOtpUpdateManyAndReturnArgs<ExtArgs>>): Prisma.PrismaPromise<$Result.GetResult<Prisma.$PhoneOtpPayload<ExtArgs>, T, "updateManyAndReturn", GlobalOmitOptions>>

    /**
     * Create or update one PhoneOtp.
     * @param {PhoneOtpUpsertArgs} args - Arguments to update or create a PhoneOtp.
     * @example
     * // Update or create a PhoneOtp
     * const phoneOtp = await prisma.phoneOtp.upsert({
     *   create: {
     *     // ... data to create a PhoneOtp
     *   },
     *   update: {
     *     // ... in case it already exists, update
     *   },
     *   where: {
     *     // ... the filter for the PhoneOtp we want to update
     *   }
     * })
     */
    upsert<T extends PhoneOtpUpsertArgs>(args: SelectSubset<T, PhoneOtpUpsertArgs<ExtArgs>>): Prisma__PhoneOtpClient<$Result.GetResult<Prisma.$PhoneOtpPayload<ExtArgs>, T, "upsert", GlobalOmitOptions>, never, ExtArgs, GlobalOmitOptions>


    /**
     * Count the number of PhoneOtps.
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * @param {PhoneOtpCountArgs} args - Arguments to filter PhoneOtps to count.
     * @example
     * // Count the number of PhoneOtps
     * const count = await prisma.phoneOtp.count({
     *   where: {
     *     // ... the filter for the PhoneOtps we want to count
     *   }
     * })
    **/
    count<T extends PhoneOtpCountArgs>(
      args?: Subset<T, PhoneOtpCountArgs>,
    ): Prisma.PrismaPromise<
      T extends $Utils.Record<'select', any>
        ? T['select'] extends true
          ? number
          : GetScalarType<T['select'], PhoneOtpCountAggregateOutputType>
        : number
    >

    /**
     * Allows you to perform aggregations operations on a PhoneOtp.
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * @param {PhoneOtpAggregateArgs} args - Select which aggregations you would like to apply and on what fields.
     * @example
     * // Ordered by age ascending
     * // Where email contains prisma.io
     * // Limited to the 10 users
     * const aggregations = await prisma.user.aggregate({
     *   _avg: {
     *     age: true,
     *   },
     *   where: {
     *     email: {
     *       contains: "prisma.io",
     *     },
     *   },
     *   orderBy: {
     *     age: "asc",
     *   },
     *   take: 10,
     * })
    **/
    aggregate<T extends PhoneOtpAggregateArgs>(args: Subset<T, PhoneOtpAggregateArgs>): Prisma.PrismaPromise<GetPhoneOtpAggregateType<T>>

    /**
     * Group by PhoneOtp.
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * @param {PhoneOtpGroupByArgs} args - Group by arguments.
     * @example
     * // Group by city, order by createdAt, get count
     * const result = await prisma.user.groupBy({
     *   by: ['city', 'createdAt'],
     *   orderBy: {
     *     createdAt: true
     *   },
     *   _count: {
     *     _all: true
     *   },
     * })
     * 
    **/
    groupBy<
      T extends PhoneOtpGroupByArgs,
      HasSelectOrTake extends Or<
        Extends<'skip', Keys<T>>,
        Extends<'take', Keys<T>>
      >,
      OrderByArg extends True extends HasSelectOrTake
        ? { orderBy: PhoneOtpGroupByArgs['orderBy'] }
        : { orderBy?: PhoneOtpGroupByArgs['orderBy'] },
      OrderFields extends ExcludeUnderscoreKeys<Keys<MaybeTupleToUnion<T['orderBy']>>>,
      ByFields extends MaybeTupleToUnion<T['by']>,
      ByValid extends Has<ByFields, OrderFields>,
      HavingFields extends GetHavingFields<T['having']>,
      HavingValid extends Has<ByFields, HavingFields>,
      ByEmpty extends T['by'] extends never[] ? True : False,
      InputErrors extends ByEmpty extends True
      ? `Error: "by" must not be empty.`
      : HavingValid extends False
      ? {
          [P in HavingFields]: P extends ByFields
            ? never
            : P extends string
            ? `Error: Field "${P}" used in "having" needs to be provided in "by".`
            : [
                Error,
                'Field ',
                P,
                ` in "having" needs to be provided in "by"`,
              ]
        }[HavingFields]
      : 'take' extends Keys<T>
      ? 'orderBy' extends Keys<T>
        ? ByValid extends True
          ? {}
          : {
              [P in OrderFields]: P extends ByFields
                ? never
                : `Error: Field "${P}" in "orderBy" needs to be provided in "by"`
            }[OrderFields]
        : 'Error: If you provide "take", you also need to provide "orderBy"'
      : 'skip' extends Keys<T>
      ? 'orderBy' extends Keys<T>
        ? ByValid extends True
          ? {}
          : {
              [P in OrderFields]: P extends ByFields
                ? never
                : `Error: Field "${P}" in "orderBy" needs to be provided in "by"`
            }[OrderFields]
        : 'Error: If you provide "skip", you also need to provide "orderBy"'
      : ByValid extends True
      ? {}
      : {
          [P in OrderFields]: P extends ByFields
            ? never
            : `Error: Field "${P}" in "orderBy" needs to be provided in "by"`
        }[OrderFields]
    >(args: SubsetIntersection<T, PhoneOtpGroupByArgs, OrderByArg> & InputErrors): {} extends InputErrors ? GetPhoneOtpGroupByPayload<T> : Prisma.PrismaPromise<InputErrors>
  /**
   * Fields of the PhoneOtp model
   */
  readonly fields: PhoneOtpFieldRefs;
  }

  /**
   * The delegate class that acts as a "Promise-like" for PhoneOtp.
   * Why is this prefixed with `Prisma__`?
   * Because we want to prevent naming conflicts as mentioned in
   * https://github.com/prisma/prisma-client-js/issues/707
   */
  export interface Prisma__PhoneOtpClient<T, Null = never, ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs, GlobalOmitOptions = {}> extends Prisma.PrismaPromise<T> {
    readonly [Symbol.toStringTag]: "PrismaPromise"
    /**
     * Attaches callbacks for the resolution and/or rejection of the Promise.
     * @param onfulfilled The callback to execute when the Promise is resolved.
     * @param onrejected The callback to execute when the Promise is rejected.
     * @returns A Promise for the completion of which ever callback is executed.
     */
    then<TResult1 = T, TResult2 = never>(onfulfilled?: ((value: T) => TResult1 | PromiseLike<TResult1>) | undefined | null, onrejected?: ((reason: any) => TResult2 | PromiseLike<TResult2>) | undefined | null): $Utils.JsPromise<TResult1 | TResult2>
    /**
     * Attaches a callback for only the rejection of the Promise.
     * @param onrejected The callback to execute when the Promise is rejected.
     * @returns A Promise for the completion of the callback.
     */
    catch<TResult = never>(onrejected?: ((reason: any) => TResult | PromiseLike<TResult>) | undefined | null): $Utils.JsPromise<T | TResult>
    /**
     * Attaches a callback that is invoked when the Promise is settled (fulfilled or rejected). The
     * resolved value cannot be modified from the callback.
     * @param onfinally The callback to execute when the Promise is settled (fulfilled or rejected).
     * @returns A Promise for the completion of the callback.
     */
    finally(onfinally?: (() => void) | undefined | null): $Utils.JsPromise<T>
  }




  /**
   * Fields of the PhoneOtp model
   */
  interface PhoneOtpFieldRefs {
    readonly id: FieldRef<"PhoneOtp", 'String'>
    readonly createdAt: FieldRef<"PhoneOtp", 'DateTime'>
    readonly phoneNumber: FieldRef<"PhoneOtp", 'String'>
    readonly code: FieldRef<"PhoneOtp", 'String'>
    readonly expiresAt: FieldRef<"PhoneOtp", 'DateTime'>
    readonly attemptCount: FieldRef<"PhoneOtp", 'Int'>
  }
    

  // Custom InputTypes
  /**
   * PhoneOtp findUnique
   */
  export type PhoneOtpFindUniqueArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the PhoneOtp
     */
    select?: PhoneOtpSelect<ExtArgs> | null
    /**
     * Omit specific fields from the PhoneOtp
     */
    omit?: PhoneOtpOmit<ExtArgs> | null
    /**
     * Filter, which PhoneOtp to fetch.
     */
    where: PhoneOtpWhereUniqueInput
  }

  /**
   * PhoneOtp findUniqueOrThrow
   */
  export type PhoneOtpFindUniqueOrThrowArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the PhoneOtp
     */
    select?: PhoneOtpSelect<ExtArgs> | null
    /**
     * Omit specific fields from the PhoneOtp
     */
    omit?: PhoneOtpOmit<ExtArgs> | null
    /**
     * Filter, which PhoneOtp to fetch.
     */
    where: PhoneOtpWhereUniqueInput
  }

  /**
   * PhoneOtp findFirst
   */
  export type PhoneOtpFindFirstArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the PhoneOtp
     */
    select?: PhoneOtpSelect<ExtArgs> | null
    /**
     * Omit specific fields from the PhoneOtp
     */
    omit?: PhoneOtpOmit<ExtArgs> | null
    /**
     * Filter, which PhoneOtp to fetch.
     */
    where?: PhoneOtpWhereInput
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/sorting Sorting Docs}
     * 
     * Determine the order of PhoneOtps to fetch.
     */
    orderBy?: PhoneOtpOrderByWithRelationInput | PhoneOtpOrderByWithRelationInput[]
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination#cursor-based-pagination Cursor Docs}
     * 
     * Sets the position for searching for PhoneOtps.
     */
    cursor?: PhoneOtpWhereUniqueInput
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination Pagination Docs}
     * 
     * Take `±n` PhoneOtps from the position of the cursor.
     */
    take?: number
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination Pagination Docs}
     * 
     * Skip the first `n` PhoneOtps.
     */
    skip?: number
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/distinct Distinct Docs}
     * 
     * Filter by unique combinations of PhoneOtps.
     */
    distinct?: PhoneOtpScalarFieldEnum | PhoneOtpScalarFieldEnum[]
  }

  /**
   * PhoneOtp findFirstOrThrow
   */
  export type PhoneOtpFindFirstOrThrowArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the PhoneOtp
     */
    select?: PhoneOtpSelect<ExtArgs> | null
    /**
     * Omit specific fields from the PhoneOtp
     */
    omit?: PhoneOtpOmit<ExtArgs> | null
    /**
     * Filter, which PhoneOtp to fetch.
     */
    where?: PhoneOtpWhereInput
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/sorting Sorting Docs}
     * 
     * Determine the order of PhoneOtps to fetch.
     */
    orderBy?: PhoneOtpOrderByWithRelationInput | PhoneOtpOrderByWithRelationInput[]
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination#cursor-based-pagination Cursor Docs}
     * 
     * Sets the position for searching for PhoneOtps.
     */
    cursor?: PhoneOtpWhereUniqueInput
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination Pagination Docs}
     * 
     * Take `±n` PhoneOtps from the position of the cursor.
     */
    take?: number
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination Pagination Docs}
     * 
     * Skip the first `n` PhoneOtps.
     */
    skip?: number
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/distinct Distinct Docs}
     * 
     * Filter by unique combinations of PhoneOtps.
     */
    distinct?: PhoneOtpScalarFieldEnum | PhoneOtpScalarFieldEnum[]
  }

  /**
   * PhoneOtp findMany
   */
  export type PhoneOtpFindManyArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the PhoneOtp
     */
    select?: PhoneOtpSelect<ExtArgs> | null
    /**
     * Omit specific fields from the PhoneOtp
     */
    omit?: PhoneOtpOmit<ExtArgs> | null
    /**
     * Filter, which PhoneOtps to fetch.
     */
    where?: PhoneOtpWhereInput
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/sorting Sorting Docs}
     * 
     * Determine the order of PhoneOtps to fetch.
     */
    orderBy?: PhoneOtpOrderByWithRelationInput | PhoneOtpOrderByWithRelationInput[]
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination#cursor-based-pagination Cursor Docs}
     * 
     * Sets the position for listing PhoneOtps.
     */
    cursor?: PhoneOtpWhereUniqueInput
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination Pagination Docs}
     * 
     * Take `±n` PhoneOtps from the position of the cursor.
     */
    take?: number
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination Pagination Docs}
     * 
     * Skip the first `n` PhoneOtps.
     */
    skip?: number
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/distinct Distinct Docs}
     * 
     * Filter by unique combinations of PhoneOtps.
     */
    distinct?: PhoneOtpScalarFieldEnum | PhoneOtpScalarFieldEnum[]
  }

  /**
   * PhoneOtp create
   */
  export type PhoneOtpCreateArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the PhoneOtp
     */
    select?: PhoneOtpSelect<ExtArgs> | null
    /**
     * Omit specific fields from the PhoneOtp
     */
    omit?: PhoneOtpOmit<ExtArgs> | null
    /**
     * The data needed to create a PhoneOtp.
     */
    data: XOR<PhoneOtpCreateInput, PhoneOtpUncheckedCreateInput>
  }

  /**
   * PhoneOtp createMany
   */
  export type PhoneOtpCreateManyArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * The data used to create many PhoneOtps.
     */
    data: PhoneOtpCreateManyInput | PhoneOtpCreateManyInput[]
    skipDuplicates?: boolean
  }

  /**
   * PhoneOtp createManyAndReturn
   */
  export type PhoneOtpCreateManyAndReturnArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the PhoneOtp
     */
    select?: PhoneOtpSelectCreateManyAndReturn<ExtArgs> | null
    /**
     * Omit specific fields from the PhoneOtp
     */
    omit?: PhoneOtpOmit<ExtArgs> | null
    /**
     * The data used to create many PhoneOtps.
     */
    data: PhoneOtpCreateManyInput | PhoneOtpCreateManyInput[]
    skipDuplicates?: boolean
  }

  /**
   * PhoneOtp update
   */
  export type PhoneOtpUpdateArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the PhoneOtp
     */
    select?: PhoneOtpSelect<ExtArgs> | null
    /**
     * Omit specific fields from the PhoneOtp
     */
    omit?: PhoneOtpOmit<ExtArgs> | null
    /**
     * The data needed to update a PhoneOtp.
     */
    data: XOR<PhoneOtpUpdateInput, PhoneOtpUncheckedUpdateInput>
    /**
     * Choose, which PhoneOtp to update.
     */
    where: PhoneOtpWhereUniqueInput
  }

  /**
   * PhoneOtp updateMany
   */
  export type PhoneOtpUpdateManyArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * The data used to update PhoneOtps.
     */
    data: XOR<PhoneOtpUpdateManyMutationInput, PhoneOtpUncheckedUpdateManyInput>
    /**
     * Filter which PhoneOtps to update
     */
    where?: PhoneOtpWhereInput
    /**
     * Limit how many PhoneOtps to update.
     */
    limit?: number
  }

  /**
   * PhoneOtp updateManyAndReturn
   */
  export type PhoneOtpUpdateManyAndReturnArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the PhoneOtp
     */
    select?: PhoneOtpSelectUpdateManyAndReturn<ExtArgs> | null
    /**
     * Omit specific fields from the PhoneOtp
     */
    omit?: PhoneOtpOmit<ExtArgs> | null
    /**
     * The data used to update PhoneOtps.
     */
    data: XOR<PhoneOtpUpdateManyMutationInput, PhoneOtpUncheckedUpdateManyInput>
    /**
     * Filter which PhoneOtps to update
     */
    where?: PhoneOtpWhereInput
    /**
     * Limit how many PhoneOtps to update.
     */
    limit?: number
  }

  /**
   * PhoneOtp upsert
   */
  export type PhoneOtpUpsertArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the PhoneOtp
     */
    select?: PhoneOtpSelect<ExtArgs> | null
    /**
     * Omit specific fields from the PhoneOtp
     */
    omit?: PhoneOtpOmit<ExtArgs> | null
    /**
     * The filter to search for the PhoneOtp to update in case it exists.
     */
    where: PhoneOtpWhereUniqueInput
    /**
     * In case the PhoneOtp found by the `where` argument doesn't exist, create a new PhoneOtp with this data.
     */
    create: XOR<PhoneOtpCreateInput, PhoneOtpUncheckedCreateInput>
    /**
     * In case the PhoneOtp was found with the provided `where` argument, update it with this data.
     */
    update: XOR<PhoneOtpUpdateInput, PhoneOtpUncheckedUpdateInput>
  }

  /**
   * PhoneOtp delete
   */
  export type PhoneOtpDeleteArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the PhoneOtp
     */
    select?: PhoneOtpSelect<ExtArgs> | null
    /**
     * Omit specific fields from the PhoneOtp
     */
    omit?: PhoneOtpOmit<ExtArgs> | null
    /**
     * Filter which PhoneOtp to delete.
     */
    where: PhoneOtpWhereUniqueInput
  }

  /**
   * PhoneOtp deleteMany
   */
  export type PhoneOtpDeleteManyArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Filter which PhoneOtps to delete
     */
    where?: PhoneOtpWhereInput
    /**
     * Limit how many PhoneOtps to delete.
     */
    limit?: number
  }

  /**
   * PhoneOtp without action
   */
  export type PhoneOtpDefaultArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the PhoneOtp
     */
    select?: PhoneOtpSelect<ExtArgs> | null
    /**
     * Omit specific fields from the PhoneOtp
     */
    omit?: PhoneOtpOmit<ExtArgs> | null
  }


  /**
   * Model LoginFailure
   */

  export type AggregateLoginFailure = {
    _count: LoginFailureCountAggregateOutputType | null
    _avg: LoginFailureAvgAggregateOutputType | null
    _sum: LoginFailureSumAggregateOutputType | null
    _min: LoginFailureMinAggregateOutputType | null
    _max: LoginFailureMaxAggregateOutputType | null
  }

  export type LoginFailureAvgAggregateOutputType = {
    attemptCount: number | null
  }

  export type LoginFailureSumAggregateOutputType = {
    attemptCount: number | null
  }

  export type LoginFailureMinAggregateOutputType = {
    id: string | null
    phoneNumber: string | null
    firstFailedAt: Date | null
    attemptCount: number | null
  }

  export type LoginFailureMaxAggregateOutputType = {
    id: string | null
    phoneNumber: string | null
    firstFailedAt: Date | null
    attemptCount: number | null
  }

  export type LoginFailureCountAggregateOutputType = {
    id: number
    phoneNumber: number
    firstFailedAt: number
    attemptCount: number
    _all: number
  }


  export type LoginFailureAvgAggregateInputType = {
    attemptCount?: true
  }

  export type LoginFailureSumAggregateInputType = {
    attemptCount?: true
  }

  export type LoginFailureMinAggregateInputType = {
    id?: true
    phoneNumber?: true
    firstFailedAt?: true
    attemptCount?: true
  }

  export type LoginFailureMaxAggregateInputType = {
    id?: true
    phoneNumber?: true
    firstFailedAt?: true
    attemptCount?: true
  }

  export type LoginFailureCountAggregateInputType = {
    id?: true
    phoneNumber?: true
    firstFailedAt?: true
    attemptCount?: true
    _all?: true
  }

  export type LoginFailureAggregateArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Filter which LoginFailure to aggregate.
     */
    where?: LoginFailureWhereInput
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/sorting Sorting Docs}
     * 
     * Determine the order of LoginFailures to fetch.
     */
    orderBy?: LoginFailureOrderByWithRelationInput | LoginFailureOrderByWithRelationInput[]
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination#cursor-based-pagination Cursor Docs}
     * 
     * Sets the start position
     */
    cursor?: LoginFailureWhereUniqueInput
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination Pagination Docs}
     * 
     * Take `±n` LoginFailures from the position of the cursor.
     */
    take?: number
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination Pagination Docs}
     * 
     * Skip the first `n` LoginFailures.
     */
    skip?: number
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/aggregations Aggregation Docs}
     * 
     * Count returned LoginFailures
    **/
    _count?: true | LoginFailureCountAggregateInputType
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/aggregations Aggregation Docs}
     * 
     * Select which fields to average
    **/
    _avg?: LoginFailureAvgAggregateInputType
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/aggregations Aggregation Docs}
     * 
     * Select which fields to sum
    **/
    _sum?: LoginFailureSumAggregateInputType
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/aggregations Aggregation Docs}
     * 
     * Select which fields to find the minimum value
    **/
    _min?: LoginFailureMinAggregateInputType
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/aggregations Aggregation Docs}
     * 
     * Select which fields to find the maximum value
    **/
    _max?: LoginFailureMaxAggregateInputType
  }

  export type GetLoginFailureAggregateType<T extends LoginFailureAggregateArgs> = {
        [P in keyof T & keyof AggregateLoginFailure]: P extends '_count' | 'count'
      ? T[P] extends true
        ? number
        : GetScalarType<T[P], AggregateLoginFailure[P]>
      : GetScalarType<T[P], AggregateLoginFailure[P]>
  }




  export type LoginFailureGroupByArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    where?: LoginFailureWhereInput
    orderBy?: LoginFailureOrderByWithAggregationInput | LoginFailureOrderByWithAggregationInput[]
    by: LoginFailureScalarFieldEnum[] | LoginFailureScalarFieldEnum
    having?: LoginFailureScalarWhereWithAggregatesInput
    take?: number
    skip?: number
    _count?: LoginFailureCountAggregateInputType | true
    _avg?: LoginFailureAvgAggregateInputType
    _sum?: LoginFailureSumAggregateInputType
    _min?: LoginFailureMinAggregateInputType
    _max?: LoginFailureMaxAggregateInputType
  }

  export type LoginFailureGroupByOutputType = {
    id: string
    phoneNumber: string
    firstFailedAt: Date
    attemptCount: number
    _count: LoginFailureCountAggregateOutputType | null
    _avg: LoginFailureAvgAggregateOutputType | null
    _sum: LoginFailureSumAggregateOutputType | null
    _min: LoginFailureMinAggregateOutputType | null
    _max: LoginFailureMaxAggregateOutputType | null
  }

  type GetLoginFailureGroupByPayload<T extends LoginFailureGroupByArgs> = Prisma.PrismaPromise<
    Array<
      PickEnumerable<LoginFailureGroupByOutputType, T['by']> &
        {
          [P in ((keyof T) & (keyof LoginFailureGroupByOutputType))]: P extends '_count'
            ? T[P] extends boolean
              ? number
              : GetScalarType<T[P], LoginFailureGroupByOutputType[P]>
            : GetScalarType<T[P], LoginFailureGroupByOutputType[P]>
        }
      >
    >


  export type LoginFailureSelect<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = $Extensions.GetSelect<{
    id?: boolean
    phoneNumber?: boolean
    firstFailedAt?: boolean
    attemptCount?: boolean
  }, ExtArgs["result"]["loginFailure"]>

  export type LoginFailureSelectCreateManyAndReturn<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = $Extensions.GetSelect<{
    id?: boolean
    phoneNumber?: boolean
    firstFailedAt?: boolean
    attemptCount?: boolean
  }, ExtArgs["result"]["loginFailure"]>

  export type LoginFailureSelectUpdateManyAndReturn<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = $Extensions.GetSelect<{
    id?: boolean
    phoneNumber?: boolean
    firstFailedAt?: boolean
    attemptCount?: boolean
  }, ExtArgs["result"]["loginFailure"]>

  export type LoginFailureSelectScalar = {
    id?: boolean
    phoneNumber?: boolean
    firstFailedAt?: boolean
    attemptCount?: boolean
  }

  export type LoginFailureOmit<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = $Extensions.GetOmit<"id" | "phoneNumber" | "firstFailedAt" | "attemptCount", ExtArgs["result"]["loginFailure"]>

  export type $LoginFailurePayload<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    name: "LoginFailure"
    objects: {}
    scalars: $Extensions.GetPayloadResult<{
      id: string
      phoneNumber: string
      firstFailedAt: Date
      attemptCount: number
    }, ExtArgs["result"]["loginFailure"]>
    composites: {}
  }

  type LoginFailureGetPayload<S extends boolean | null | undefined | LoginFailureDefaultArgs> = $Result.GetResult<Prisma.$LoginFailurePayload, S>

  type LoginFailureCountArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> =
    Omit<LoginFailureFindManyArgs, 'select' | 'include' | 'distinct' | 'omit'> & {
      select?: LoginFailureCountAggregateInputType | true
    }

  export interface LoginFailureDelegate<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs, GlobalOmitOptions = {}> {
    [K: symbol]: { types: Prisma.TypeMap<ExtArgs>['model']['LoginFailure'], meta: { name: 'LoginFailure' } }
    /**
     * Find zero or one LoginFailure that matches the filter.
     * @param {LoginFailureFindUniqueArgs} args - Arguments to find a LoginFailure
     * @example
     * // Get one LoginFailure
     * const loginFailure = await prisma.loginFailure.findUnique({
     *   where: {
     *     // ... provide filter here
     *   }
     * })
     */
    findUnique<T extends LoginFailureFindUniqueArgs>(args: SelectSubset<T, LoginFailureFindUniqueArgs<ExtArgs>>): Prisma__LoginFailureClient<$Result.GetResult<Prisma.$LoginFailurePayload<ExtArgs>, T, "findUnique", GlobalOmitOptions> | null, null, ExtArgs, GlobalOmitOptions>

    /**
     * Find one LoginFailure that matches the filter or throw an error with `error.code='P2025'`
     * if no matches were found.
     * @param {LoginFailureFindUniqueOrThrowArgs} args - Arguments to find a LoginFailure
     * @example
     * // Get one LoginFailure
     * const loginFailure = await prisma.loginFailure.findUniqueOrThrow({
     *   where: {
     *     // ... provide filter here
     *   }
     * })
     */
    findUniqueOrThrow<T extends LoginFailureFindUniqueOrThrowArgs>(args: SelectSubset<T, LoginFailureFindUniqueOrThrowArgs<ExtArgs>>): Prisma__LoginFailureClient<$Result.GetResult<Prisma.$LoginFailurePayload<ExtArgs>, T, "findUniqueOrThrow", GlobalOmitOptions>, never, ExtArgs, GlobalOmitOptions>

    /**
     * Find the first LoginFailure that matches the filter.
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * @param {LoginFailureFindFirstArgs} args - Arguments to find a LoginFailure
     * @example
     * // Get one LoginFailure
     * const loginFailure = await prisma.loginFailure.findFirst({
     *   where: {
     *     // ... provide filter here
     *   }
     * })
     */
    findFirst<T extends LoginFailureFindFirstArgs>(args?: SelectSubset<T, LoginFailureFindFirstArgs<ExtArgs>>): Prisma__LoginFailureClient<$Result.GetResult<Prisma.$LoginFailurePayload<ExtArgs>, T, "findFirst", GlobalOmitOptions> | null, null, ExtArgs, GlobalOmitOptions>

    /**
     * Find the first LoginFailure that matches the filter or
     * throw `PrismaKnownClientError` with `P2025` code if no matches were found.
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * @param {LoginFailureFindFirstOrThrowArgs} args - Arguments to find a LoginFailure
     * @example
     * // Get one LoginFailure
     * const loginFailure = await prisma.loginFailure.findFirstOrThrow({
     *   where: {
     *     // ... provide filter here
     *   }
     * })
     */
    findFirstOrThrow<T extends LoginFailureFindFirstOrThrowArgs>(args?: SelectSubset<T, LoginFailureFindFirstOrThrowArgs<ExtArgs>>): Prisma__LoginFailureClient<$Result.GetResult<Prisma.$LoginFailurePayload<ExtArgs>, T, "findFirstOrThrow", GlobalOmitOptions>, never, ExtArgs, GlobalOmitOptions>

    /**
     * Find zero or more LoginFailures that matches the filter.
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * @param {LoginFailureFindManyArgs} args - Arguments to filter and select certain fields only.
     * @example
     * // Get all LoginFailures
     * const loginFailures = await prisma.loginFailure.findMany()
     * 
     * // Get first 10 LoginFailures
     * const loginFailures = await prisma.loginFailure.findMany({ take: 10 })
     * 
     * // Only select the `id`
     * const loginFailureWithIdOnly = await prisma.loginFailure.findMany({ select: { id: true } })
     * 
     */
    findMany<T extends LoginFailureFindManyArgs>(args?: SelectSubset<T, LoginFailureFindManyArgs<ExtArgs>>): Prisma.PrismaPromise<$Result.GetResult<Prisma.$LoginFailurePayload<ExtArgs>, T, "findMany", GlobalOmitOptions>>

    /**
     * Create a LoginFailure.
     * @param {LoginFailureCreateArgs} args - Arguments to create a LoginFailure.
     * @example
     * // Create one LoginFailure
     * const LoginFailure = await prisma.loginFailure.create({
     *   data: {
     *     // ... data to create a LoginFailure
     *   }
     * })
     * 
     */
    create<T extends LoginFailureCreateArgs>(args: SelectSubset<T, LoginFailureCreateArgs<ExtArgs>>): Prisma__LoginFailureClient<$Result.GetResult<Prisma.$LoginFailurePayload<ExtArgs>, T, "create", GlobalOmitOptions>, never, ExtArgs, GlobalOmitOptions>

    /**
     * Create many LoginFailures.
     * @param {LoginFailureCreateManyArgs} args - Arguments to create many LoginFailures.
     * @example
     * // Create many LoginFailures
     * const loginFailure = await prisma.loginFailure.createMany({
     *   data: [
     *     // ... provide data here
     *   ]
     * })
     *     
     */
    createMany<T extends LoginFailureCreateManyArgs>(args?: SelectSubset<T, LoginFailureCreateManyArgs<ExtArgs>>): Prisma.PrismaPromise<BatchPayload>

    /**
     * Create many LoginFailures and returns the data saved in the database.
     * @param {LoginFailureCreateManyAndReturnArgs} args - Arguments to create many LoginFailures.
     * @example
     * // Create many LoginFailures
     * const loginFailure = await prisma.loginFailure.createManyAndReturn({
     *   data: [
     *     // ... provide data here
     *   ]
     * })
     * 
     * // Create many LoginFailures and only return the `id`
     * const loginFailureWithIdOnly = await prisma.loginFailure.createManyAndReturn({
     *   select: { id: true },
     *   data: [
     *     // ... provide data here
     *   ]
     * })
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * 
     */
    createManyAndReturn<T extends LoginFailureCreateManyAndReturnArgs>(args?: SelectSubset<T, LoginFailureCreateManyAndReturnArgs<ExtArgs>>): Prisma.PrismaPromise<$Result.GetResult<Prisma.$LoginFailurePayload<ExtArgs>, T, "createManyAndReturn", GlobalOmitOptions>>

    /**
     * Delete a LoginFailure.
     * @param {LoginFailureDeleteArgs} args - Arguments to delete one LoginFailure.
     * @example
     * // Delete one LoginFailure
     * const LoginFailure = await prisma.loginFailure.delete({
     *   where: {
     *     // ... filter to delete one LoginFailure
     *   }
     * })
     * 
     */
    delete<T extends LoginFailureDeleteArgs>(args: SelectSubset<T, LoginFailureDeleteArgs<ExtArgs>>): Prisma__LoginFailureClient<$Result.GetResult<Prisma.$LoginFailurePayload<ExtArgs>, T, "delete", GlobalOmitOptions>, never, ExtArgs, GlobalOmitOptions>

    /**
     * Update one LoginFailure.
     * @param {LoginFailureUpdateArgs} args - Arguments to update one LoginFailure.
     * @example
     * // Update one LoginFailure
     * const loginFailure = await prisma.loginFailure.update({
     *   where: {
     *     // ... provide filter here
     *   },
     *   data: {
     *     // ... provide data here
     *   }
     * })
     * 
     */
    update<T extends LoginFailureUpdateArgs>(args: SelectSubset<T, LoginFailureUpdateArgs<ExtArgs>>): Prisma__LoginFailureClient<$Result.GetResult<Prisma.$LoginFailurePayload<ExtArgs>, T, "update", GlobalOmitOptions>, never, ExtArgs, GlobalOmitOptions>

    /**
     * Delete zero or more LoginFailures.
     * @param {LoginFailureDeleteManyArgs} args - Arguments to filter LoginFailures to delete.
     * @example
     * // Delete a few LoginFailures
     * const { count } = await prisma.loginFailure.deleteMany({
     *   where: {
     *     // ... provide filter here
     *   }
     * })
     * 
     */
    deleteMany<T extends LoginFailureDeleteManyArgs>(args?: SelectSubset<T, LoginFailureDeleteManyArgs<ExtArgs>>): Prisma.PrismaPromise<BatchPayload>

    /**
     * Update zero or more LoginFailures.
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * @param {LoginFailureUpdateManyArgs} args - Arguments to update one or more rows.
     * @example
     * // Update many LoginFailures
     * const loginFailure = await prisma.loginFailure.updateMany({
     *   where: {
     *     // ... provide filter here
     *   },
     *   data: {
     *     // ... provide data here
     *   }
     * })
     * 
     */
    updateMany<T extends LoginFailureUpdateManyArgs>(args: SelectSubset<T, LoginFailureUpdateManyArgs<ExtArgs>>): Prisma.PrismaPromise<BatchPayload>

    /**
     * Update zero or more LoginFailures and returns the data updated in the database.
     * @param {LoginFailureUpdateManyAndReturnArgs} args - Arguments to update many LoginFailures.
     * @example
     * // Update many LoginFailures
     * const loginFailure = await prisma.loginFailure.updateManyAndReturn({
     *   where: {
     *     // ... provide filter here
     *   },
     *   data: [
     *     // ... provide data here
     *   ]
     * })
     * 
     * // Update zero or more LoginFailures and only return the `id`
     * const loginFailureWithIdOnly = await prisma.loginFailure.updateManyAndReturn({
     *   select: { id: true },
     *   where: {
     *     // ... provide filter here
     *   },
     *   data: [
     *     // ... provide data here
     *   ]
     * })
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * 
     */
    updateManyAndReturn<T extends LoginFailureUpdateManyAndReturnArgs>(args: SelectSubset<T, LoginFailureUpdateManyAndReturnArgs<ExtArgs>>): Prisma.PrismaPromise<$Result.GetResult<Prisma.$LoginFailurePayload<ExtArgs>, T, "updateManyAndReturn", GlobalOmitOptions>>

    /**
     * Create or update one LoginFailure.
     * @param {LoginFailureUpsertArgs} args - Arguments to update or create a LoginFailure.
     * @example
     * // Update or create a LoginFailure
     * const loginFailure = await prisma.loginFailure.upsert({
     *   create: {
     *     // ... data to create a LoginFailure
     *   },
     *   update: {
     *     // ... in case it already exists, update
     *   },
     *   where: {
     *     // ... the filter for the LoginFailure we want to update
     *   }
     * })
     */
    upsert<T extends LoginFailureUpsertArgs>(args: SelectSubset<T, LoginFailureUpsertArgs<ExtArgs>>): Prisma__LoginFailureClient<$Result.GetResult<Prisma.$LoginFailurePayload<ExtArgs>, T, "upsert", GlobalOmitOptions>, never, ExtArgs, GlobalOmitOptions>


    /**
     * Count the number of LoginFailures.
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * @param {LoginFailureCountArgs} args - Arguments to filter LoginFailures to count.
     * @example
     * // Count the number of LoginFailures
     * const count = await prisma.loginFailure.count({
     *   where: {
     *     // ... the filter for the LoginFailures we want to count
     *   }
     * })
    **/
    count<T extends LoginFailureCountArgs>(
      args?: Subset<T, LoginFailureCountArgs>,
    ): Prisma.PrismaPromise<
      T extends $Utils.Record<'select', any>
        ? T['select'] extends true
          ? number
          : GetScalarType<T['select'], LoginFailureCountAggregateOutputType>
        : number
    >

    /**
     * Allows you to perform aggregations operations on a LoginFailure.
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * @param {LoginFailureAggregateArgs} args - Select which aggregations you would like to apply and on what fields.
     * @example
     * // Ordered by age ascending
     * // Where email contains prisma.io
     * // Limited to the 10 users
     * const aggregations = await prisma.user.aggregate({
     *   _avg: {
     *     age: true,
     *   },
     *   where: {
     *     email: {
     *       contains: "prisma.io",
     *     },
     *   },
     *   orderBy: {
     *     age: "asc",
     *   },
     *   take: 10,
     * })
    **/
    aggregate<T extends LoginFailureAggregateArgs>(args: Subset<T, LoginFailureAggregateArgs>): Prisma.PrismaPromise<GetLoginFailureAggregateType<T>>

    /**
     * Group by LoginFailure.
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * @param {LoginFailureGroupByArgs} args - Group by arguments.
     * @example
     * // Group by city, order by createdAt, get count
     * const result = await prisma.user.groupBy({
     *   by: ['city', 'createdAt'],
     *   orderBy: {
     *     createdAt: true
     *   },
     *   _count: {
     *     _all: true
     *   },
     * })
     * 
    **/
    groupBy<
      T extends LoginFailureGroupByArgs,
      HasSelectOrTake extends Or<
        Extends<'skip', Keys<T>>,
        Extends<'take', Keys<T>>
      >,
      OrderByArg extends True extends HasSelectOrTake
        ? { orderBy: LoginFailureGroupByArgs['orderBy'] }
        : { orderBy?: LoginFailureGroupByArgs['orderBy'] },
      OrderFields extends ExcludeUnderscoreKeys<Keys<MaybeTupleToUnion<T['orderBy']>>>,
      ByFields extends MaybeTupleToUnion<T['by']>,
      ByValid extends Has<ByFields, OrderFields>,
      HavingFields extends GetHavingFields<T['having']>,
      HavingValid extends Has<ByFields, HavingFields>,
      ByEmpty extends T['by'] extends never[] ? True : False,
      InputErrors extends ByEmpty extends True
      ? `Error: "by" must not be empty.`
      : HavingValid extends False
      ? {
          [P in HavingFields]: P extends ByFields
            ? never
            : P extends string
            ? `Error: Field "${P}" used in "having" needs to be provided in "by".`
            : [
                Error,
                'Field ',
                P,
                ` in "having" needs to be provided in "by"`,
              ]
        }[HavingFields]
      : 'take' extends Keys<T>
      ? 'orderBy' extends Keys<T>
        ? ByValid extends True
          ? {}
          : {
              [P in OrderFields]: P extends ByFields
                ? never
                : `Error: Field "${P}" in "orderBy" needs to be provided in "by"`
            }[OrderFields]
        : 'Error: If you provide "take", you also need to provide "orderBy"'
      : 'skip' extends Keys<T>
      ? 'orderBy' extends Keys<T>
        ? ByValid extends True
          ? {}
          : {
              [P in OrderFields]: P extends ByFields
                ? never
                : `Error: Field "${P}" in "orderBy" needs to be provided in "by"`
            }[OrderFields]
        : 'Error: If you provide "skip", you also need to provide "orderBy"'
      : ByValid extends True
      ? {}
      : {
          [P in OrderFields]: P extends ByFields
            ? never
            : `Error: Field "${P}" in "orderBy" needs to be provided in "by"`
        }[OrderFields]
    >(args: SubsetIntersection<T, LoginFailureGroupByArgs, OrderByArg> & InputErrors): {} extends InputErrors ? GetLoginFailureGroupByPayload<T> : Prisma.PrismaPromise<InputErrors>
  /**
   * Fields of the LoginFailure model
   */
  readonly fields: LoginFailureFieldRefs;
  }

  /**
   * The delegate class that acts as a "Promise-like" for LoginFailure.
   * Why is this prefixed with `Prisma__`?
   * Because we want to prevent naming conflicts as mentioned in
   * https://github.com/prisma/prisma-client-js/issues/707
   */
  export interface Prisma__LoginFailureClient<T, Null = never, ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs, GlobalOmitOptions = {}> extends Prisma.PrismaPromise<T> {
    readonly [Symbol.toStringTag]: "PrismaPromise"
    /**
     * Attaches callbacks for the resolution and/or rejection of the Promise.
     * @param onfulfilled The callback to execute when the Promise is resolved.
     * @param onrejected The callback to execute when the Promise is rejected.
     * @returns A Promise for the completion of which ever callback is executed.
     */
    then<TResult1 = T, TResult2 = never>(onfulfilled?: ((value: T) => TResult1 | PromiseLike<TResult1>) | undefined | null, onrejected?: ((reason: any) => TResult2 | PromiseLike<TResult2>) | undefined | null): $Utils.JsPromise<TResult1 | TResult2>
    /**
     * Attaches a callback for only the rejection of the Promise.
     * @param onrejected The callback to execute when the Promise is rejected.
     * @returns A Promise for the completion of the callback.
     */
    catch<TResult = never>(onrejected?: ((reason: any) => TResult | PromiseLike<TResult>) | undefined | null): $Utils.JsPromise<T | TResult>
    /**
     * Attaches a callback that is invoked when the Promise is settled (fulfilled or rejected). The
     * resolved value cannot be modified from the callback.
     * @param onfinally The callback to execute when the Promise is settled (fulfilled or rejected).
     * @returns A Promise for the completion of the callback.
     */
    finally(onfinally?: (() => void) | undefined | null): $Utils.JsPromise<T>
  }




  /**
   * Fields of the LoginFailure model
   */
  interface LoginFailureFieldRefs {
    readonly id: FieldRef<"LoginFailure", 'String'>
    readonly phoneNumber: FieldRef<"LoginFailure", 'String'>
    readonly firstFailedAt: FieldRef<"LoginFailure", 'DateTime'>
    readonly attemptCount: FieldRef<"LoginFailure", 'Int'>
  }
    

  // Custom InputTypes
  /**
   * LoginFailure findUnique
   */
  export type LoginFailureFindUniqueArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the LoginFailure
     */
    select?: LoginFailureSelect<ExtArgs> | null
    /**
     * Omit specific fields from the LoginFailure
     */
    omit?: LoginFailureOmit<ExtArgs> | null
    /**
     * Filter, which LoginFailure to fetch.
     */
    where: LoginFailureWhereUniqueInput
  }

  /**
   * LoginFailure findUniqueOrThrow
   */
  export type LoginFailureFindUniqueOrThrowArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the LoginFailure
     */
    select?: LoginFailureSelect<ExtArgs> | null
    /**
     * Omit specific fields from the LoginFailure
     */
    omit?: LoginFailureOmit<ExtArgs> | null
    /**
     * Filter, which LoginFailure to fetch.
     */
    where: LoginFailureWhereUniqueInput
  }

  /**
   * LoginFailure findFirst
   */
  export type LoginFailureFindFirstArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the LoginFailure
     */
    select?: LoginFailureSelect<ExtArgs> | null
    /**
     * Omit specific fields from the LoginFailure
     */
    omit?: LoginFailureOmit<ExtArgs> | null
    /**
     * Filter, which LoginFailure to fetch.
     */
    where?: LoginFailureWhereInput
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/sorting Sorting Docs}
     * 
     * Determine the order of LoginFailures to fetch.
     */
    orderBy?: LoginFailureOrderByWithRelationInput | LoginFailureOrderByWithRelationInput[]
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination#cursor-based-pagination Cursor Docs}
     * 
     * Sets the position for searching for LoginFailures.
     */
    cursor?: LoginFailureWhereUniqueInput
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination Pagination Docs}
     * 
     * Take `±n` LoginFailures from the position of the cursor.
     */
    take?: number
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination Pagination Docs}
     * 
     * Skip the first `n` LoginFailures.
     */
    skip?: number
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/distinct Distinct Docs}
     * 
     * Filter by unique combinations of LoginFailures.
     */
    distinct?: LoginFailureScalarFieldEnum | LoginFailureScalarFieldEnum[]
  }

  /**
   * LoginFailure findFirstOrThrow
   */
  export type LoginFailureFindFirstOrThrowArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the LoginFailure
     */
    select?: LoginFailureSelect<ExtArgs> | null
    /**
     * Omit specific fields from the LoginFailure
     */
    omit?: LoginFailureOmit<ExtArgs> | null
    /**
     * Filter, which LoginFailure to fetch.
     */
    where?: LoginFailureWhereInput
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/sorting Sorting Docs}
     * 
     * Determine the order of LoginFailures to fetch.
     */
    orderBy?: LoginFailureOrderByWithRelationInput | LoginFailureOrderByWithRelationInput[]
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination#cursor-based-pagination Cursor Docs}
     * 
     * Sets the position for searching for LoginFailures.
     */
    cursor?: LoginFailureWhereUniqueInput
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination Pagination Docs}
     * 
     * Take `±n` LoginFailures from the position of the cursor.
     */
    take?: number
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination Pagination Docs}
     * 
     * Skip the first `n` LoginFailures.
     */
    skip?: number
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/distinct Distinct Docs}
     * 
     * Filter by unique combinations of LoginFailures.
     */
    distinct?: LoginFailureScalarFieldEnum | LoginFailureScalarFieldEnum[]
  }

  /**
   * LoginFailure findMany
   */
  export type LoginFailureFindManyArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the LoginFailure
     */
    select?: LoginFailureSelect<ExtArgs> | null
    /**
     * Omit specific fields from the LoginFailure
     */
    omit?: LoginFailureOmit<ExtArgs> | null
    /**
     * Filter, which LoginFailures to fetch.
     */
    where?: LoginFailureWhereInput
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/sorting Sorting Docs}
     * 
     * Determine the order of LoginFailures to fetch.
     */
    orderBy?: LoginFailureOrderByWithRelationInput | LoginFailureOrderByWithRelationInput[]
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination#cursor-based-pagination Cursor Docs}
     * 
     * Sets the position for listing LoginFailures.
     */
    cursor?: LoginFailureWhereUniqueInput
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination Pagination Docs}
     * 
     * Take `±n` LoginFailures from the position of the cursor.
     */
    take?: number
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination Pagination Docs}
     * 
     * Skip the first `n` LoginFailures.
     */
    skip?: number
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/distinct Distinct Docs}
     * 
     * Filter by unique combinations of LoginFailures.
     */
    distinct?: LoginFailureScalarFieldEnum | LoginFailureScalarFieldEnum[]
  }

  /**
   * LoginFailure create
   */
  export type LoginFailureCreateArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the LoginFailure
     */
    select?: LoginFailureSelect<ExtArgs> | null
    /**
     * Omit specific fields from the LoginFailure
     */
    omit?: LoginFailureOmit<ExtArgs> | null
    /**
     * The data needed to create a LoginFailure.
     */
    data: XOR<LoginFailureCreateInput, LoginFailureUncheckedCreateInput>
  }

  /**
   * LoginFailure createMany
   */
  export type LoginFailureCreateManyArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * The data used to create many LoginFailures.
     */
    data: LoginFailureCreateManyInput | LoginFailureCreateManyInput[]
    skipDuplicates?: boolean
  }

  /**
   * LoginFailure createManyAndReturn
   */
  export type LoginFailureCreateManyAndReturnArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the LoginFailure
     */
    select?: LoginFailureSelectCreateManyAndReturn<ExtArgs> | null
    /**
     * Omit specific fields from the LoginFailure
     */
    omit?: LoginFailureOmit<ExtArgs> | null
    /**
     * The data used to create many LoginFailures.
     */
    data: LoginFailureCreateManyInput | LoginFailureCreateManyInput[]
    skipDuplicates?: boolean
  }

  /**
   * LoginFailure update
   */
  export type LoginFailureUpdateArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the LoginFailure
     */
    select?: LoginFailureSelect<ExtArgs> | null
    /**
     * Omit specific fields from the LoginFailure
     */
    omit?: LoginFailureOmit<ExtArgs> | null
    /**
     * The data needed to update a LoginFailure.
     */
    data: XOR<LoginFailureUpdateInput, LoginFailureUncheckedUpdateInput>
    /**
     * Choose, which LoginFailure to update.
     */
    where: LoginFailureWhereUniqueInput
  }

  /**
   * LoginFailure updateMany
   */
  export type LoginFailureUpdateManyArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * The data used to update LoginFailures.
     */
    data: XOR<LoginFailureUpdateManyMutationInput, LoginFailureUncheckedUpdateManyInput>
    /**
     * Filter which LoginFailures to update
     */
    where?: LoginFailureWhereInput
    /**
     * Limit how many LoginFailures to update.
     */
    limit?: number
  }

  /**
   * LoginFailure updateManyAndReturn
   */
  export type LoginFailureUpdateManyAndReturnArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the LoginFailure
     */
    select?: LoginFailureSelectUpdateManyAndReturn<ExtArgs> | null
    /**
     * Omit specific fields from the LoginFailure
     */
    omit?: LoginFailureOmit<ExtArgs> | null
    /**
     * The data used to update LoginFailures.
     */
    data: XOR<LoginFailureUpdateManyMutationInput, LoginFailureUncheckedUpdateManyInput>
    /**
     * Filter which LoginFailures to update
     */
    where?: LoginFailureWhereInput
    /**
     * Limit how many LoginFailures to update.
     */
    limit?: number
  }

  /**
   * LoginFailure upsert
   */
  export type LoginFailureUpsertArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the LoginFailure
     */
    select?: LoginFailureSelect<ExtArgs> | null
    /**
     * Omit specific fields from the LoginFailure
     */
    omit?: LoginFailureOmit<ExtArgs> | null
    /**
     * The filter to search for the LoginFailure to update in case it exists.
     */
    where: LoginFailureWhereUniqueInput
    /**
     * In case the LoginFailure found by the `where` argument doesn't exist, create a new LoginFailure with this data.
     */
    create: XOR<LoginFailureCreateInput, LoginFailureUncheckedCreateInput>
    /**
     * In case the LoginFailure was found with the provided `where` argument, update it with this data.
     */
    update: XOR<LoginFailureUpdateInput, LoginFailureUncheckedUpdateInput>
  }

  /**
   * LoginFailure delete
   */
  export type LoginFailureDeleteArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the LoginFailure
     */
    select?: LoginFailureSelect<ExtArgs> | null
    /**
     * Omit specific fields from the LoginFailure
     */
    omit?: LoginFailureOmit<ExtArgs> | null
    /**
     * Filter which LoginFailure to delete.
     */
    where: LoginFailureWhereUniqueInput
  }

  /**
   * LoginFailure deleteMany
   */
  export type LoginFailureDeleteManyArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Filter which LoginFailures to delete
     */
    where?: LoginFailureWhereInput
    /**
     * Limit how many LoginFailures to delete.
     */
    limit?: number
  }

  /**
   * LoginFailure without action
   */
  export type LoginFailureDefaultArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the LoginFailure
     */
    select?: LoginFailureSelect<ExtArgs> | null
    /**
     * Omit specific fields from the LoginFailure
     */
    omit?: LoginFailureOmit<ExtArgs> | null
  }


  /**
   * Model AdminNotification
   */

  export type AggregateAdminNotification = {
    _count: AdminNotificationCountAggregateOutputType | null
    _min: AdminNotificationMinAggregateOutputType | null
    _max: AdminNotificationMaxAggregateOutputType | null
  }

  export type AdminNotificationMinAggregateOutputType = {
    id: string | null
    createdAt: Date | null
    updatedAt: Date | null
    userId: string | null
    title: string | null
    message: string | null
    timeLabel: string | null
    tone: $Enums.AdminNotificationTone | null
    category: $Enums.AdminNotificationCategory | null
    isUnread: boolean | null
    href: string | null
  }

  export type AdminNotificationMaxAggregateOutputType = {
    id: string | null
    createdAt: Date | null
    updatedAt: Date | null
    userId: string | null
    title: string | null
    message: string | null
    timeLabel: string | null
    tone: $Enums.AdminNotificationTone | null
    category: $Enums.AdminNotificationCategory | null
    isUnread: boolean | null
    href: string | null
  }

  export type AdminNotificationCountAggregateOutputType = {
    id: number
    createdAt: number
    updatedAt: number
    userId: number
    title: number
    message: number
    timeLabel: number
    tone: number
    category: number
    isUnread: number
    href: number
    _all: number
  }


  export type AdminNotificationMinAggregateInputType = {
    id?: true
    createdAt?: true
    updatedAt?: true
    userId?: true
    title?: true
    message?: true
    timeLabel?: true
    tone?: true
    category?: true
    isUnread?: true
    href?: true
  }

  export type AdminNotificationMaxAggregateInputType = {
    id?: true
    createdAt?: true
    updatedAt?: true
    userId?: true
    title?: true
    message?: true
    timeLabel?: true
    tone?: true
    category?: true
    isUnread?: true
    href?: true
  }

  export type AdminNotificationCountAggregateInputType = {
    id?: true
    createdAt?: true
    updatedAt?: true
    userId?: true
    title?: true
    message?: true
    timeLabel?: true
    tone?: true
    category?: true
    isUnread?: true
    href?: true
    _all?: true
  }

  export type AdminNotificationAggregateArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Filter which AdminNotification to aggregate.
     */
    where?: AdminNotificationWhereInput
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/sorting Sorting Docs}
     * 
     * Determine the order of AdminNotifications to fetch.
     */
    orderBy?: AdminNotificationOrderByWithRelationInput | AdminNotificationOrderByWithRelationInput[]
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination#cursor-based-pagination Cursor Docs}
     * 
     * Sets the start position
     */
    cursor?: AdminNotificationWhereUniqueInput
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination Pagination Docs}
     * 
     * Take `±n` AdminNotifications from the position of the cursor.
     */
    take?: number
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination Pagination Docs}
     * 
     * Skip the first `n` AdminNotifications.
     */
    skip?: number
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/aggregations Aggregation Docs}
     * 
     * Count returned AdminNotifications
    **/
    _count?: true | AdminNotificationCountAggregateInputType
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/aggregations Aggregation Docs}
     * 
     * Select which fields to find the minimum value
    **/
    _min?: AdminNotificationMinAggregateInputType
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/aggregations Aggregation Docs}
     * 
     * Select which fields to find the maximum value
    **/
    _max?: AdminNotificationMaxAggregateInputType
  }

  export type GetAdminNotificationAggregateType<T extends AdminNotificationAggregateArgs> = {
        [P in keyof T & keyof AggregateAdminNotification]: P extends '_count' | 'count'
      ? T[P] extends true
        ? number
        : GetScalarType<T[P], AggregateAdminNotification[P]>
      : GetScalarType<T[P], AggregateAdminNotification[P]>
  }




  export type AdminNotificationGroupByArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    where?: AdminNotificationWhereInput
    orderBy?: AdminNotificationOrderByWithAggregationInput | AdminNotificationOrderByWithAggregationInput[]
    by: AdminNotificationScalarFieldEnum[] | AdminNotificationScalarFieldEnum
    having?: AdminNotificationScalarWhereWithAggregatesInput
    take?: number
    skip?: number
    _count?: AdminNotificationCountAggregateInputType | true
    _min?: AdminNotificationMinAggregateInputType
    _max?: AdminNotificationMaxAggregateInputType
  }

  export type AdminNotificationGroupByOutputType = {
    id: string
    createdAt: Date
    updatedAt: Date
    userId: string | null
    title: string
    message: string
    timeLabel: string
    tone: $Enums.AdminNotificationTone
    category: $Enums.AdminNotificationCategory
    isUnread: boolean
    href: string | null
    _count: AdminNotificationCountAggregateOutputType | null
    _min: AdminNotificationMinAggregateOutputType | null
    _max: AdminNotificationMaxAggregateOutputType | null
  }

  type GetAdminNotificationGroupByPayload<T extends AdminNotificationGroupByArgs> = Prisma.PrismaPromise<
    Array<
      PickEnumerable<AdminNotificationGroupByOutputType, T['by']> &
        {
          [P in ((keyof T) & (keyof AdminNotificationGroupByOutputType))]: P extends '_count'
            ? T[P] extends boolean
              ? number
              : GetScalarType<T[P], AdminNotificationGroupByOutputType[P]>
            : GetScalarType<T[P], AdminNotificationGroupByOutputType[P]>
        }
      >
    >


  export type AdminNotificationSelect<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = $Extensions.GetSelect<{
    id?: boolean
    createdAt?: boolean
    updatedAt?: boolean
    userId?: boolean
    title?: boolean
    message?: boolean
    timeLabel?: boolean
    tone?: boolean
    category?: boolean
    isUnread?: boolean
    href?: boolean
    user?: boolean | AdminNotification$userArgs<ExtArgs>
  }, ExtArgs["result"]["adminNotification"]>

  export type AdminNotificationSelectCreateManyAndReturn<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = $Extensions.GetSelect<{
    id?: boolean
    createdAt?: boolean
    updatedAt?: boolean
    userId?: boolean
    title?: boolean
    message?: boolean
    timeLabel?: boolean
    tone?: boolean
    category?: boolean
    isUnread?: boolean
    href?: boolean
    user?: boolean | AdminNotification$userArgs<ExtArgs>
  }, ExtArgs["result"]["adminNotification"]>

  export type AdminNotificationSelectUpdateManyAndReturn<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = $Extensions.GetSelect<{
    id?: boolean
    createdAt?: boolean
    updatedAt?: boolean
    userId?: boolean
    title?: boolean
    message?: boolean
    timeLabel?: boolean
    tone?: boolean
    category?: boolean
    isUnread?: boolean
    href?: boolean
    user?: boolean | AdminNotification$userArgs<ExtArgs>
  }, ExtArgs["result"]["adminNotification"]>

  export type AdminNotificationSelectScalar = {
    id?: boolean
    createdAt?: boolean
    updatedAt?: boolean
    userId?: boolean
    title?: boolean
    message?: boolean
    timeLabel?: boolean
    tone?: boolean
    category?: boolean
    isUnread?: boolean
    href?: boolean
  }

  export type AdminNotificationOmit<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = $Extensions.GetOmit<"id" | "createdAt" | "updatedAt" | "userId" | "title" | "message" | "timeLabel" | "tone" | "category" | "isUnread" | "href", ExtArgs["result"]["adminNotification"]>
  export type AdminNotificationInclude<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    user?: boolean | AdminNotification$userArgs<ExtArgs>
  }
  export type AdminNotificationIncludeCreateManyAndReturn<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    user?: boolean | AdminNotification$userArgs<ExtArgs>
  }
  export type AdminNotificationIncludeUpdateManyAndReturn<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    user?: boolean | AdminNotification$userArgs<ExtArgs>
  }

  export type $AdminNotificationPayload<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    name: "AdminNotification"
    objects: {
      user: Prisma.$UserPayload<ExtArgs> | null
    }
    scalars: $Extensions.GetPayloadResult<{
      id: string
      createdAt: Date
      updatedAt: Date
      userId: string | null
      title: string
      message: string
      timeLabel: string
      tone: $Enums.AdminNotificationTone
      category: $Enums.AdminNotificationCategory
      isUnread: boolean
      href: string | null
    }, ExtArgs["result"]["adminNotification"]>
    composites: {}
  }

  type AdminNotificationGetPayload<S extends boolean | null | undefined | AdminNotificationDefaultArgs> = $Result.GetResult<Prisma.$AdminNotificationPayload, S>

  type AdminNotificationCountArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> =
    Omit<AdminNotificationFindManyArgs, 'select' | 'include' | 'distinct' | 'omit'> & {
      select?: AdminNotificationCountAggregateInputType | true
    }

  export interface AdminNotificationDelegate<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs, GlobalOmitOptions = {}> {
    [K: symbol]: { types: Prisma.TypeMap<ExtArgs>['model']['AdminNotification'], meta: { name: 'AdminNotification' } }
    /**
     * Find zero or one AdminNotification that matches the filter.
     * @param {AdminNotificationFindUniqueArgs} args - Arguments to find a AdminNotification
     * @example
     * // Get one AdminNotification
     * const adminNotification = await prisma.adminNotification.findUnique({
     *   where: {
     *     // ... provide filter here
     *   }
     * })
     */
    findUnique<T extends AdminNotificationFindUniqueArgs>(args: SelectSubset<T, AdminNotificationFindUniqueArgs<ExtArgs>>): Prisma__AdminNotificationClient<$Result.GetResult<Prisma.$AdminNotificationPayload<ExtArgs>, T, "findUnique", GlobalOmitOptions> | null, null, ExtArgs, GlobalOmitOptions>

    /**
     * Find one AdminNotification that matches the filter or throw an error with `error.code='P2025'`
     * if no matches were found.
     * @param {AdminNotificationFindUniqueOrThrowArgs} args - Arguments to find a AdminNotification
     * @example
     * // Get one AdminNotification
     * const adminNotification = await prisma.adminNotification.findUniqueOrThrow({
     *   where: {
     *     // ... provide filter here
     *   }
     * })
     */
    findUniqueOrThrow<T extends AdminNotificationFindUniqueOrThrowArgs>(args: SelectSubset<T, AdminNotificationFindUniqueOrThrowArgs<ExtArgs>>): Prisma__AdminNotificationClient<$Result.GetResult<Prisma.$AdminNotificationPayload<ExtArgs>, T, "findUniqueOrThrow", GlobalOmitOptions>, never, ExtArgs, GlobalOmitOptions>

    /**
     * Find the first AdminNotification that matches the filter.
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * @param {AdminNotificationFindFirstArgs} args - Arguments to find a AdminNotification
     * @example
     * // Get one AdminNotification
     * const adminNotification = await prisma.adminNotification.findFirst({
     *   where: {
     *     // ... provide filter here
     *   }
     * })
     */
    findFirst<T extends AdminNotificationFindFirstArgs>(args?: SelectSubset<T, AdminNotificationFindFirstArgs<ExtArgs>>): Prisma__AdminNotificationClient<$Result.GetResult<Prisma.$AdminNotificationPayload<ExtArgs>, T, "findFirst", GlobalOmitOptions> | null, null, ExtArgs, GlobalOmitOptions>

    /**
     * Find the first AdminNotification that matches the filter or
     * throw `PrismaKnownClientError` with `P2025` code if no matches were found.
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * @param {AdminNotificationFindFirstOrThrowArgs} args - Arguments to find a AdminNotification
     * @example
     * // Get one AdminNotification
     * const adminNotification = await prisma.adminNotification.findFirstOrThrow({
     *   where: {
     *     // ... provide filter here
     *   }
     * })
     */
    findFirstOrThrow<T extends AdminNotificationFindFirstOrThrowArgs>(args?: SelectSubset<T, AdminNotificationFindFirstOrThrowArgs<ExtArgs>>): Prisma__AdminNotificationClient<$Result.GetResult<Prisma.$AdminNotificationPayload<ExtArgs>, T, "findFirstOrThrow", GlobalOmitOptions>, never, ExtArgs, GlobalOmitOptions>

    /**
     * Find zero or more AdminNotifications that matches the filter.
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * @param {AdminNotificationFindManyArgs} args - Arguments to filter and select certain fields only.
     * @example
     * // Get all AdminNotifications
     * const adminNotifications = await prisma.adminNotification.findMany()
     * 
     * // Get first 10 AdminNotifications
     * const adminNotifications = await prisma.adminNotification.findMany({ take: 10 })
     * 
     * // Only select the `id`
     * const adminNotificationWithIdOnly = await prisma.adminNotification.findMany({ select: { id: true } })
     * 
     */
    findMany<T extends AdminNotificationFindManyArgs>(args?: SelectSubset<T, AdminNotificationFindManyArgs<ExtArgs>>): Prisma.PrismaPromise<$Result.GetResult<Prisma.$AdminNotificationPayload<ExtArgs>, T, "findMany", GlobalOmitOptions>>

    /**
     * Create a AdminNotification.
     * @param {AdminNotificationCreateArgs} args - Arguments to create a AdminNotification.
     * @example
     * // Create one AdminNotification
     * const AdminNotification = await prisma.adminNotification.create({
     *   data: {
     *     // ... data to create a AdminNotification
     *   }
     * })
     * 
     */
    create<T extends AdminNotificationCreateArgs>(args: SelectSubset<T, AdminNotificationCreateArgs<ExtArgs>>): Prisma__AdminNotificationClient<$Result.GetResult<Prisma.$AdminNotificationPayload<ExtArgs>, T, "create", GlobalOmitOptions>, never, ExtArgs, GlobalOmitOptions>

    /**
     * Create many AdminNotifications.
     * @param {AdminNotificationCreateManyArgs} args - Arguments to create many AdminNotifications.
     * @example
     * // Create many AdminNotifications
     * const adminNotification = await prisma.adminNotification.createMany({
     *   data: [
     *     // ... provide data here
     *   ]
     * })
     *     
     */
    createMany<T extends AdminNotificationCreateManyArgs>(args?: SelectSubset<T, AdminNotificationCreateManyArgs<ExtArgs>>): Prisma.PrismaPromise<BatchPayload>

    /**
     * Create many AdminNotifications and returns the data saved in the database.
     * @param {AdminNotificationCreateManyAndReturnArgs} args - Arguments to create many AdminNotifications.
     * @example
     * // Create many AdminNotifications
     * const adminNotification = await prisma.adminNotification.createManyAndReturn({
     *   data: [
     *     // ... provide data here
     *   ]
     * })
     * 
     * // Create many AdminNotifications and only return the `id`
     * const adminNotificationWithIdOnly = await prisma.adminNotification.createManyAndReturn({
     *   select: { id: true },
     *   data: [
     *     // ... provide data here
     *   ]
     * })
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * 
     */
    createManyAndReturn<T extends AdminNotificationCreateManyAndReturnArgs>(args?: SelectSubset<T, AdminNotificationCreateManyAndReturnArgs<ExtArgs>>): Prisma.PrismaPromise<$Result.GetResult<Prisma.$AdminNotificationPayload<ExtArgs>, T, "createManyAndReturn", GlobalOmitOptions>>

    /**
     * Delete a AdminNotification.
     * @param {AdminNotificationDeleteArgs} args - Arguments to delete one AdminNotification.
     * @example
     * // Delete one AdminNotification
     * const AdminNotification = await prisma.adminNotification.delete({
     *   where: {
     *     // ... filter to delete one AdminNotification
     *   }
     * })
     * 
     */
    delete<T extends AdminNotificationDeleteArgs>(args: SelectSubset<T, AdminNotificationDeleteArgs<ExtArgs>>): Prisma__AdminNotificationClient<$Result.GetResult<Prisma.$AdminNotificationPayload<ExtArgs>, T, "delete", GlobalOmitOptions>, never, ExtArgs, GlobalOmitOptions>

    /**
     * Update one AdminNotification.
     * @param {AdminNotificationUpdateArgs} args - Arguments to update one AdminNotification.
     * @example
     * // Update one AdminNotification
     * const adminNotification = await prisma.adminNotification.update({
     *   where: {
     *     // ... provide filter here
     *   },
     *   data: {
     *     // ... provide data here
     *   }
     * })
     * 
     */
    update<T extends AdminNotificationUpdateArgs>(args: SelectSubset<T, AdminNotificationUpdateArgs<ExtArgs>>): Prisma__AdminNotificationClient<$Result.GetResult<Prisma.$AdminNotificationPayload<ExtArgs>, T, "update", GlobalOmitOptions>, never, ExtArgs, GlobalOmitOptions>

    /**
     * Delete zero or more AdminNotifications.
     * @param {AdminNotificationDeleteManyArgs} args - Arguments to filter AdminNotifications to delete.
     * @example
     * // Delete a few AdminNotifications
     * const { count } = await prisma.adminNotification.deleteMany({
     *   where: {
     *     // ... provide filter here
     *   }
     * })
     * 
     */
    deleteMany<T extends AdminNotificationDeleteManyArgs>(args?: SelectSubset<T, AdminNotificationDeleteManyArgs<ExtArgs>>): Prisma.PrismaPromise<BatchPayload>

    /**
     * Update zero or more AdminNotifications.
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * @param {AdminNotificationUpdateManyArgs} args - Arguments to update one or more rows.
     * @example
     * // Update many AdminNotifications
     * const adminNotification = await prisma.adminNotification.updateMany({
     *   where: {
     *     // ... provide filter here
     *   },
     *   data: {
     *     // ... provide data here
     *   }
     * })
     * 
     */
    updateMany<T extends AdminNotificationUpdateManyArgs>(args: SelectSubset<T, AdminNotificationUpdateManyArgs<ExtArgs>>): Prisma.PrismaPromise<BatchPayload>

    /**
     * Update zero or more AdminNotifications and returns the data updated in the database.
     * @param {AdminNotificationUpdateManyAndReturnArgs} args - Arguments to update many AdminNotifications.
     * @example
     * // Update many AdminNotifications
     * const adminNotification = await prisma.adminNotification.updateManyAndReturn({
     *   where: {
     *     // ... provide filter here
     *   },
     *   data: [
     *     // ... provide data here
     *   ]
     * })
     * 
     * // Update zero or more AdminNotifications and only return the `id`
     * const adminNotificationWithIdOnly = await prisma.adminNotification.updateManyAndReturn({
     *   select: { id: true },
     *   where: {
     *     // ... provide filter here
     *   },
     *   data: [
     *     // ... provide data here
     *   ]
     * })
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * 
     */
    updateManyAndReturn<T extends AdminNotificationUpdateManyAndReturnArgs>(args: SelectSubset<T, AdminNotificationUpdateManyAndReturnArgs<ExtArgs>>): Prisma.PrismaPromise<$Result.GetResult<Prisma.$AdminNotificationPayload<ExtArgs>, T, "updateManyAndReturn", GlobalOmitOptions>>

    /**
     * Create or update one AdminNotification.
     * @param {AdminNotificationUpsertArgs} args - Arguments to update or create a AdminNotification.
     * @example
     * // Update or create a AdminNotification
     * const adminNotification = await prisma.adminNotification.upsert({
     *   create: {
     *     // ... data to create a AdminNotification
     *   },
     *   update: {
     *     // ... in case it already exists, update
     *   },
     *   where: {
     *     // ... the filter for the AdminNotification we want to update
     *   }
     * })
     */
    upsert<T extends AdminNotificationUpsertArgs>(args: SelectSubset<T, AdminNotificationUpsertArgs<ExtArgs>>): Prisma__AdminNotificationClient<$Result.GetResult<Prisma.$AdminNotificationPayload<ExtArgs>, T, "upsert", GlobalOmitOptions>, never, ExtArgs, GlobalOmitOptions>


    /**
     * Count the number of AdminNotifications.
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * @param {AdminNotificationCountArgs} args - Arguments to filter AdminNotifications to count.
     * @example
     * // Count the number of AdminNotifications
     * const count = await prisma.adminNotification.count({
     *   where: {
     *     // ... the filter for the AdminNotifications we want to count
     *   }
     * })
    **/
    count<T extends AdminNotificationCountArgs>(
      args?: Subset<T, AdminNotificationCountArgs>,
    ): Prisma.PrismaPromise<
      T extends $Utils.Record<'select', any>
        ? T['select'] extends true
          ? number
          : GetScalarType<T['select'], AdminNotificationCountAggregateOutputType>
        : number
    >

    /**
     * Allows you to perform aggregations operations on a AdminNotification.
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * @param {AdminNotificationAggregateArgs} args - Select which aggregations you would like to apply and on what fields.
     * @example
     * // Ordered by age ascending
     * // Where email contains prisma.io
     * // Limited to the 10 users
     * const aggregations = await prisma.user.aggregate({
     *   _avg: {
     *     age: true,
     *   },
     *   where: {
     *     email: {
     *       contains: "prisma.io",
     *     },
     *   },
     *   orderBy: {
     *     age: "asc",
     *   },
     *   take: 10,
     * })
    **/
    aggregate<T extends AdminNotificationAggregateArgs>(args: Subset<T, AdminNotificationAggregateArgs>): Prisma.PrismaPromise<GetAdminNotificationAggregateType<T>>

    /**
     * Group by AdminNotification.
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * @param {AdminNotificationGroupByArgs} args - Group by arguments.
     * @example
     * // Group by city, order by createdAt, get count
     * const result = await prisma.user.groupBy({
     *   by: ['city', 'createdAt'],
     *   orderBy: {
     *     createdAt: true
     *   },
     *   _count: {
     *     _all: true
     *   },
     * })
     * 
    **/
    groupBy<
      T extends AdminNotificationGroupByArgs,
      HasSelectOrTake extends Or<
        Extends<'skip', Keys<T>>,
        Extends<'take', Keys<T>>
      >,
      OrderByArg extends True extends HasSelectOrTake
        ? { orderBy: AdminNotificationGroupByArgs['orderBy'] }
        : { orderBy?: AdminNotificationGroupByArgs['orderBy'] },
      OrderFields extends ExcludeUnderscoreKeys<Keys<MaybeTupleToUnion<T['orderBy']>>>,
      ByFields extends MaybeTupleToUnion<T['by']>,
      ByValid extends Has<ByFields, OrderFields>,
      HavingFields extends GetHavingFields<T['having']>,
      HavingValid extends Has<ByFields, HavingFields>,
      ByEmpty extends T['by'] extends never[] ? True : False,
      InputErrors extends ByEmpty extends True
      ? `Error: "by" must not be empty.`
      : HavingValid extends False
      ? {
          [P in HavingFields]: P extends ByFields
            ? never
            : P extends string
            ? `Error: Field "${P}" used in "having" needs to be provided in "by".`
            : [
                Error,
                'Field ',
                P,
                ` in "having" needs to be provided in "by"`,
              ]
        }[HavingFields]
      : 'take' extends Keys<T>
      ? 'orderBy' extends Keys<T>
        ? ByValid extends True
          ? {}
          : {
              [P in OrderFields]: P extends ByFields
                ? never
                : `Error: Field "${P}" in "orderBy" needs to be provided in "by"`
            }[OrderFields]
        : 'Error: If you provide "take", you also need to provide "orderBy"'
      : 'skip' extends Keys<T>
      ? 'orderBy' extends Keys<T>
        ? ByValid extends True
          ? {}
          : {
              [P in OrderFields]: P extends ByFields
                ? never
                : `Error: Field "${P}" in "orderBy" needs to be provided in "by"`
            }[OrderFields]
        : 'Error: If you provide "skip", you also need to provide "orderBy"'
      : ByValid extends True
      ? {}
      : {
          [P in OrderFields]: P extends ByFields
            ? never
            : `Error: Field "${P}" in "orderBy" needs to be provided in "by"`
        }[OrderFields]
    >(args: SubsetIntersection<T, AdminNotificationGroupByArgs, OrderByArg> & InputErrors): {} extends InputErrors ? GetAdminNotificationGroupByPayload<T> : Prisma.PrismaPromise<InputErrors>
  /**
   * Fields of the AdminNotification model
   */
  readonly fields: AdminNotificationFieldRefs;
  }

  /**
   * The delegate class that acts as a "Promise-like" for AdminNotification.
   * Why is this prefixed with `Prisma__`?
   * Because we want to prevent naming conflicts as mentioned in
   * https://github.com/prisma/prisma-client-js/issues/707
   */
  export interface Prisma__AdminNotificationClient<T, Null = never, ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs, GlobalOmitOptions = {}> extends Prisma.PrismaPromise<T> {
    readonly [Symbol.toStringTag]: "PrismaPromise"
    user<T extends AdminNotification$userArgs<ExtArgs> = {}>(args?: Subset<T, AdminNotification$userArgs<ExtArgs>>): Prisma__UserClient<$Result.GetResult<Prisma.$UserPayload<ExtArgs>, T, "findUniqueOrThrow", GlobalOmitOptions> | null, null, ExtArgs, GlobalOmitOptions>
    /**
     * Attaches callbacks for the resolution and/or rejection of the Promise.
     * @param onfulfilled The callback to execute when the Promise is resolved.
     * @param onrejected The callback to execute when the Promise is rejected.
     * @returns A Promise for the completion of which ever callback is executed.
     */
    then<TResult1 = T, TResult2 = never>(onfulfilled?: ((value: T) => TResult1 | PromiseLike<TResult1>) | undefined | null, onrejected?: ((reason: any) => TResult2 | PromiseLike<TResult2>) | undefined | null): $Utils.JsPromise<TResult1 | TResult2>
    /**
     * Attaches a callback for only the rejection of the Promise.
     * @param onrejected The callback to execute when the Promise is rejected.
     * @returns A Promise for the completion of the callback.
     */
    catch<TResult = never>(onrejected?: ((reason: any) => TResult | PromiseLike<TResult>) | undefined | null): $Utils.JsPromise<T | TResult>
    /**
     * Attaches a callback that is invoked when the Promise is settled (fulfilled or rejected). The
     * resolved value cannot be modified from the callback.
     * @param onfinally The callback to execute when the Promise is settled (fulfilled or rejected).
     * @returns A Promise for the completion of the callback.
     */
    finally(onfinally?: (() => void) | undefined | null): $Utils.JsPromise<T>
  }




  /**
   * Fields of the AdminNotification model
   */
  interface AdminNotificationFieldRefs {
    readonly id: FieldRef<"AdminNotification", 'String'>
    readonly createdAt: FieldRef<"AdminNotification", 'DateTime'>
    readonly updatedAt: FieldRef<"AdminNotification", 'DateTime'>
    readonly userId: FieldRef<"AdminNotification", 'String'>
    readonly title: FieldRef<"AdminNotification", 'String'>
    readonly message: FieldRef<"AdminNotification", 'String'>
    readonly timeLabel: FieldRef<"AdminNotification", 'String'>
    readonly tone: FieldRef<"AdminNotification", 'AdminNotificationTone'>
    readonly category: FieldRef<"AdminNotification", 'AdminNotificationCategory'>
    readonly isUnread: FieldRef<"AdminNotification", 'Boolean'>
    readonly href: FieldRef<"AdminNotification", 'String'>
  }
    

  // Custom InputTypes
  /**
   * AdminNotification findUnique
   */
  export type AdminNotificationFindUniqueArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the AdminNotification
     */
    select?: AdminNotificationSelect<ExtArgs> | null
    /**
     * Omit specific fields from the AdminNotification
     */
    omit?: AdminNotificationOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: AdminNotificationInclude<ExtArgs> | null
    /**
     * Filter, which AdminNotification to fetch.
     */
    where: AdminNotificationWhereUniqueInput
  }

  /**
   * AdminNotification findUniqueOrThrow
   */
  export type AdminNotificationFindUniqueOrThrowArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the AdminNotification
     */
    select?: AdminNotificationSelect<ExtArgs> | null
    /**
     * Omit specific fields from the AdminNotification
     */
    omit?: AdminNotificationOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: AdminNotificationInclude<ExtArgs> | null
    /**
     * Filter, which AdminNotification to fetch.
     */
    where: AdminNotificationWhereUniqueInput
  }

  /**
   * AdminNotification findFirst
   */
  export type AdminNotificationFindFirstArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the AdminNotification
     */
    select?: AdminNotificationSelect<ExtArgs> | null
    /**
     * Omit specific fields from the AdminNotification
     */
    omit?: AdminNotificationOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: AdminNotificationInclude<ExtArgs> | null
    /**
     * Filter, which AdminNotification to fetch.
     */
    where?: AdminNotificationWhereInput
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/sorting Sorting Docs}
     * 
     * Determine the order of AdminNotifications to fetch.
     */
    orderBy?: AdminNotificationOrderByWithRelationInput | AdminNotificationOrderByWithRelationInput[]
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination#cursor-based-pagination Cursor Docs}
     * 
     * Sets the position for searching for AdminNotifications.
     */
    cursor?: AdminNotificationWhereUniqueInput
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination Pagination Docs}
     * 
     * Take `±n` AdminNotifications from the position of the cursor.
     */
    take?: number
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination Pagination Docs}
     * 
     * Skip the first `n` AdminNotifications.
     */
    skip?: number
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/distinct Distinct Docs}
     * 
     * Filter by unique combinations of AdminNotifications.
     */
    distinct?: AdminNotificationScalarFieldEnum | AdminNotificationScalarFieldEnum[]
  }

  /**
   * AdminNotification findFirstOrThrow
   */
  export type AdminNotificationFindFirstOrThrowArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the AdminNotification
     */
    select?: AdminNotificationSelect<ExtArgs> | null
    /**
     * Omit specific fields from the AdminNotification
     */
    omit?: AdminNotificationOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: AdminNotificationInclude<ExtArgs> | null
    /**
     * Filter, which AdminNotification to fetch.
     */
    where?: AdminNotificationWhereInput
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/sorting Sorting Docs}
     * 
     * Determine the order of AdminNotifications to fetch.
     */
    orderBy?: AdminNotificationOrderByWithRelationInput | AdminNotificationOrderByWithRelationInput[]
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination#cursor-based-pagination Cursor Docs}
     * 
     * Sets the position for searching for AdminNotifications.
     */
    cursor?: AdminNotificationWhereUniqueInput
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination Pagination Docs}
     * 
     * Take `±n` AdminNotifications from the position of the cursor.
     */
    take?: number
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination Pagination Docs}
     * 
     * Skip the first `n` AdminNotifications.
     */
    skip?: number
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/distinct Distinct Docs}
     * 
     * Filter by unique combinations of AdminNotifications.
     */
    distinct?: AdminNotificationScalarFieldEnum | AdminNotificationScalarFieldEnum[]
  }

  /**
   * AdminNotification findMany
   */
  export type AdminNotificationFindManyArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the AdminNotification
     */
    select?: AdminNotificationSelect<ExtArgs> | null
    /**
     * Omit specific fields from the AdminNotification
     */
    omit?: AdminNotificationOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: AdminNotificationInclude<ExtArgs> | null
    /**
     * Filter, which AdminNotifications to fetch.
     */
    where?: AdminNotificationWhereInput
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/sorting Sorting Docs}
     * 
     * Determine the order of AdminNotifications to fetch.
     */
    orderBy?: AdminNotificationOrderByWithRelationInput | AdminNotificationOrderByWithRelationInput[]
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination#cursor-based-pagination Cursor Docs}
     * 
     * Sets the position for listing AdminNotifications.
     */
    cursor?: AdminNotificationWhereUniqueInput
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination Pagination Docs}
     * 
     * Take `±n` AdminNotifications from the position of the cursor.
     */
    take?: number
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination Pagination Docs}
     * 
     * Skip the first `n` AdminNotifications.
     */
    skip?: number
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/distinct Distinct Docs}
     * 
     * Filter by unique combinations of AdminNotifications.
     */
    distinct?: AdminNotificationScalarFieldEnum | AdminNotificationScalarFieldEnum[]
  }

  /**
   * AdminNotification create
   */
  export type AdminNotificationCreateArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the AdminNotification
     */
    select?: AdminNotificationSelect<ExtArgs> | null
    /**
     * Omit specific fields from the AdminNotification
     */
    omit?: AdminNotificationOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: AdminNotificationInclude<ExtArgs> | null
    /**
     * The data needed to create a AdminNotification.
     */
    data: XOR<AdminNotificationCreateInput, AdminNotificationUncheckedCreateInput>
  }

  /**
   * AdminNotification createMany
   */
  export type AdminNotificationCreateManyArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * The data used to create many AdminNotifications.
     */
    data: AdminNotificationCreateManyInput | AdminNotificationCreateManyInput[]
    skipDuplicates?: boolean
  }

  /**
   * AdminNotification createManyAndReturn
   */
  export type AdminNotificationCreateManyAndReturnArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the AdminNotification
     */
    select?: AdminNotificationSelectCreateManyAndReturn<ExtArgs> | null
    /**
     * Omit specific fields from the AdminNotification
     */
    omit?: AdminNotificationOmit<ExtArgs> | null
    /**
     * The data used to create many AdminNotifications.
     */
    data: AdminNotificationCreateManyInput | AdminNotificationCreateManyInput[]
    skipDuplicates?: boolean
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: AdminNotificationIncludeCreateManyAndReturn<ExtArgs> | null
  }

  /**
   * AdminNotification update
   */
  export type AdminNotificationUpdateArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the AdminNotification
     */
    select?: AdminNotificationSelect<ExtArgs> | null
    /**
     * Omit specific fields from the AdminNotification
     */
    omit?: AdminNotificationOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: AdminNotificationInclude<ExtArgs> | null
    /**
     * The data needed to update a AdminNotification.
     */
    data: XOR<AdminNotificationUpdateInput, AdminNotificationUncheckedUpdateInput>
    /**
     * Choose, which AdminNotification to update.
     */
    where: AdminNotificationWhereUniqueInput
  }

  /**
   * AdminNotification updateMany
   */
  export type AdminNotificationUpdateManyArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * The data used to update AdminNotifications.
     */
    data: XOR<AdminNotificationUpdateManyMutationInput, AdminNotificationUncheckedUpdateManyInput>
    /**
     * Filter which AdminNotifications to update
     */
    where?: AdminNotificationWhereInput
    /**
     * Limit how many AdminNotifications to update.
     */
    limit?: number
  }

  /**
   * AdminNotification updateManyAndReturn
   */
  export type AdminNotificationUpdateManyAndReturnArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the AdminNotification
     */
    select?: AdminNotificationSelectUpdateManyAndReturn<ExtArgs> | null
    /**
     * Omit specific fields from the AdminNotification
     */
    omit?: AdminNotificationOmit<ExtArgs> | null
    /**
     * The data used to update AdminNotifications.
     */
    data: XOR<AdminNotificationUpdateManyMutationInput, AdminNotificationUncheckedUpdateManyInput>
    /**
     * Filter which AdminNotifications to update
     */
    where?: AdminNotificationWhereInput
    /**
     * Limit how many AdminNotifications to update.
     */
    limit?: number
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: AdminNotificationIncludeUpdateManyAndReturn<ExtArgs> | null
  }

  /**
   * AdminNotification upsert
   */
  export type AdminNotificationUpsertArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the AdminNotification
     */
    select?: AdminNotificationSelect<ExtArgs> | null
    /**
     * Omit specific fields from the AdminNotification
     */
    omit?: AdminNotificationOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: AdminNotificationInclude<ExtArgs> | null
    /**
     * The filter to search for the AdminNotification to update in case it exists.
     */
    where: AdminNotificationWhereUniqueInput
    /**
     * In case the AdminNotification found by the `where` argument doesn't exist, create a new AdminNotification with this data.
     */
    create: XOR<AdminNotificationCreateInput, AdminNotificationUncheckedCreateInput>
    /**
     * In case the AdminNotification was found with the provided `where` argument, update it with this data.
     */
    update: XOR<AdminNotificationUpdateInput, AdminNotificationUncheckedUpdateInput>
  }

  /**
   * AdminNotification delete
   */
  export type AdminNotificationDeleteArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the AdminNotification
     */
    select?: AdminNotificationSelect<ExtArgs> | null
    /**
     * Omit specific fields from the AdminNotification
     */
    omit?: AdminNotificationOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: AdminNotificationInclude<ExtArgs> | null
    /**
     * Filter which AdminNotification to delete.
     */
    where: AdminNotificationWhereUniqueInput
  }

  /**
   * AdminNotification deleteMany
   */
  export type AdminNotificationDeleteManyArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Filter which AdminNotifications to delete
     */
    where?: AdminNotificationWhereInput
    /**
     * Limit how many AdminNotifications to delete.
     */
    limit?: number
  }

  /**
   * AdminNotification.user
   */
  export type AdminNotification$userArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the User
     */
    select?: UserSelect<ExtArgs> | null
    /**
     * Omit specific fields from the User
     */
    omit?: UserOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: UserInclude<ExtArgs> | null
    where?: UserWhereInput
  }

  /**
   * AdminNotification without action
   */
  export type AdminNotificationDefaultArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the AdminNotification
     */
    select?: AdminNotificationSelect<ExtArgs> | null
    /**
     * Omit specific fields from the AdminNotification
     */
    omit?: AdminNotificationOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: AdminNotificationInclude<ExtArgs> | null
  }


  /**
   * Model PointTransaction
   */

  export type AggregatePointTransaction = {
    _count: PointTransactionCountAggregateOutputType | null
    _avg: PointTransactionAvgAggregateOutputType | null
    _sum: PointTransactionSumAggregateOutputType | null
    _min: PointTransactionMinAggregateOutputType | null
    _max: PointTransactionMaxAggregateOutputType | null
  }

  export type PointTransactionAvgAggregateOutputType = {
    delta: number | null
    balanceAfter: number | null
  }

  export type PointTransactionSumAggregateOutputType = {
    delta: number | null
    balanceAfter: number | null
  }

  export type PointTransactionMinAggregateOutputType = {
    id: string | null
    createdAt: Date | null
    userId: string | null
    delta: number | null
    balanceAfter: number | null
    reasonCode: string | null
    referenceType: string | null
    referenceId: string | null
  }

  export type PointTransactionMaxAggregateOutputType = {
    id: string | null
    createdAt: Date | null
    userId: string | null
    delta: number | null
    balanceAfter: number | null
    reasonCode: string | null
    referenceType: string | null
    referenceId: string | null
  }

  export type PointTransactionCountAggregateOutputType = {
    id: number
    createdAt: number
    userId: number
    delta: number
    balanceAfter: number
    reasonCode: number
    referenceType: number
    referenceId: number
    metadata: number
    _all: number
  }


  export type PointTransactionAvgAggregateInputType = {
    delta?: true
    balanceAfter?: true
  }

  export type PointTransactionSumAggregateInputType = {
    delta?: true
    balanceAfter?: true
  }

  export type PointTransactionMinAggregateInputType = {
    id?: true
    createdAt?: true
    userId?: true
    delta?: true
    balanceAfter?: true
    reasonCode?: true
    referenceType?: true
    referenceId?: true
  }

  export type PointTransactionMaxAggregateInputType = {
    id?: true
    createdAt?: true
    userId?: true
    delta?: true
    balanceAfter?: true
    reasonCode?: true
    referenceType?: true
    referenceId?: true
  }

  export type PointTransactionCountAggregateInputType = {
    id?: true
    createdAt?: true
    userId?: true
    delta?: true
    balanceAfter?: true
    reasonCode?: true
    referenceType?: true
    referenceId?: true
    metadata?: true
    _all?: true
  }

  export type PointTransactionAggregateArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Filter which PointTransaction to aggregate.
     */
    where?: PointTransactionWhereInput
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/sorting Sorting Docs}
     * 
     * Determine the order of PointTransactions to fetch.
     */
    orderBy?: PointTransactionOrderByWithRelationInput | PointTransactionOrderByWithRelationInput[]
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination#cursor-based-pagination Cursor Docs}
     * 
     * Sets the start position
     */
    cursor?: PointTransactionWhereUniqueInput
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination Pagination Docs}
     * 
     * Take `±n` PointTransactions from the position of the cursor.
     */
    take?: number
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination Pagination Docs}
     * 
     * Skip the first `n` PointTransactions.
     */
    skip?: number
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/aggregations Aggregation Docs}
     * 
     * Count returned PointTransactions
    **/
    _count?: true | PointTransactionCountAggregateInputType
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/aggregations Aggregation Docs}
     * 
     * Select which fields to average
    **/
    _avg?: PointTransactionAvgAggregateInputType
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/aggregations Aggregation Docs}
     * 
     * Select which fields to sum
    **/
    _sum?: PointTransactionSumAggregateInputType
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/aggregations Aggregation Docs}
     * 
     * Select which fields to find the minimum value
    **/
    _min?: PointTransactionMinAggregateInputType
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/aggregations Aggregation Docs}
     * 
     * Select which fields to find the maximum value
    **/
    _max?: PointTransactionMaxAggregateInputType
  }

  export type GetPointTransactionAggregateType<T extends PointTransactionAggregateArgs> = {
        [P in keyof T & keyof AggregatePointTransaction]: P extends '_count' | 'count'
      ? T[P] extends true
        ? number
        : GetScalarType<T[P], AggregatePointTransaction[P]>
      : GetScalarType<T[P], AggregatePointTransaction[P]>
  }




  export type PointTransactionGroupByArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    where?: PointTransactionWhereInput
    orderBy?: PointTransactionOrderByWithAggregationInput | PointTransactionOrderByWithAggregationInput[]
    by: PointTransactionScalarFieldEnum[] | PointTransactionScalarFieldEnum
    having?: PointTransactionScalarWhereWithAggregatesInput
    take?: number
    skip?: number
    _count?: PointTransactionCountAggregateInputType | true
    _avg?: PointTransactionAvgAggregateInputType
    _sum?: PointTransactionSumAggregateInputType
    _min?: PointTransactionMinAggregateInputType
    _max?: PointTransactionMaxAggregateInputType
  }

  export type PointTransactionGroupByOutputType = {
    id: string
    createdAt: Date
    userId: string
    delta: number
    balanceAfter: number
    reasonCode: string
    referenceType: string | null
    referenceId: string | null
    metadata: JsonValue | null
    _count: PointTransactionCountAggregateOutputType | null
    _avg: PointTransactionAvgAggregateOutputType | null
    _sum: PointTransactionSumAggregateOutputType | null
    _min: PointTransactionMinAggregateOutputType | null
    _max: PointTransactionMaxAggregateOutputType | null
  }

  type GetPointTransactionGroupByPayload<T extends PointTransactionGroupByArgs> = Prisma.PrismaPromise<
    Array<
      PickEnumerable<PointTransactionGroupByOutputType, T['by']> &
        {
          [P in ((keyof T) & (keyof PointTransactionGroupByOutputType))]: P extends '_count'
            ? T[P] extends boolean
              ? number
              : GetScalarType<T[P], PointTransactionGroupByOutputType[P]>
            : GetScalarType<T[P], PointTransactionGroupByOutputType[P]>
        }
      >
    >


  export type PointTransactionSelect<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = $Extensions.GetSelect<{
    id?: boolean
    createdAt?: boolean
    userId?: boolean
    delta?: boolean
    balanceAfter?: boolean
    reasonCode?: boolean
    referenceType?: boolean
    referenceId?: boolean
    metadata?: boolean
    user?: boolean | UserDefaultArgs<ExtArgs>
  }, ExtArgs["result"]["pointTransaction"]>

  export type PointTransactionSelectCreateManyAndReturn<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = $Extensions.GetSelect<{
    id?: boolean
    createdAt?: boolean
    userId?: boolean
    delta?: boolean
    balanceAfter?: boolean
    reasonCode?: boolean
    referenceType?: boolean
    referenceId?: boolean
    metadata?: boolean
    user?: boolean | UserDefaultArgs<ExtArgs>
  }, ExtArgs["result"]["pointTransaction"]>

  export type PointTransactionSelectUpdateManyAndReturn<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = $Extensions.GetSelect<{
    id?: boolean
    createdAt?: boolean
    userId?: boolean
    delta?: boolean
    balanceAfter?: boolean
    reasonCode?: boolean
    referenceType?: boolean
    referenceId?: boolean
    metadata?: boolean
    user?: boolean | UserDefaultArgs<ExtArgs>
  }, ExtArgs["result"]["pointTransaction"]>

  export type PointTransactionSelectScalar = {
    id?: boolean
    createdAt?: boolean
    userId?: boolean
    delta?: boolean
    balanceAfter?: boolean
    reasonCode?: boolean
    referenceType?: boolean
    referenceId?: boolean
    metadata?: boolean
  }

  export type PointTransactionOmit<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = $Extensions.GetOmit<"id" | "createdAt" | "userId" | "delta" | "balanceAfter" | "reasonCode" | "referenceType" | "referenceId" | "metadata", ExtArgs["result"]["pointTransaction"]>
  export type PointTransactionInclude<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    user?: boolean | UserDefaultArgs<ExtArgs>
  }
  export type PointTransactionIncludeCreateManyAndReturn<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    user?: boolean | UserDefaultArgs<ExtArgs>
  }
  export type PointTransactionIncludeUpdateManyAndReturn<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    user?: boolean | UserDefaultArgs<ExtArgs>
  }

  export type $PointTransactionPayload<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    name: "PointTransaction"
    objects: {
      user: Prisma.$UserPayload<ExtArgs>
    }
    scalars: $Extensions.GetPayloadResult<{
      id: string
      createdAt: Date
      userId: string
      delta: number
      balanceAfter: number
      reasonCode: string
      referenceType: string | null
      referenceId: string | null
      metadata: Prisma.JsonValue | null
    }, ExtArgs["result"]["pointTransaction"]>
    composites: {}
  }

  type PointTransactionGetPayload<S extends boolean | null | undefined | PointTransactionDefaultArgs> = $Result.GetResult<Prisma.$PointTransactionPayload, S>

  type PointTransactionCountArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> =
    Omit<PointTransactionFindManyArgs, 'select' | 'include' | 'distinct' | 'omit'> & {
      select?: PointTransactionCountAggregateInputType | true
    }

  export interface PointTransactionDelegate<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs, GlobalOmitOptions = {}> {
    [K: symbol]: { types: Prisma.TypeMap<ExtArgs>['model']['PointTransaction'], meta: { name: 'PointTransaction' } }
    /**
     * Find zero or one PointTransaction that matches the filter.
     * @param {PointTransactionFindUniqueArgs} args - Arguments to find a PointTransaction
     * @example
     * // Get one PointTransaction
     * const pointTransaction = await prisma.pointTransaction.findUnique({
     *   where: {
     *     // ... provide filter here
     *   }
     * })
     */
    findUnique<T extends PointTransactionFindUniqueArgs>(args: SelectSubset<T, PointTransactionFindUniqueArgs<ExtArgs>>): Prisma__PointTransactionClient<$Result.GetResult<Prisma.$PointTransactionPayload<ExtArgs>, T, "findUnique", GlobalOmitOptions> | null, null, ExtArgs, GlobalOmitOptions>

    /**
     * Find one PointTransaction that matches the filter or throw an error with `error.code='P2025'`
     * if no matches were found.
     * @param {PointTransactionFindUniqueOrThrowArgs} args - Arguments to find a PointTransaction
     * @example
     * // Get one PointTransaction
     * const pointTransaction = await prisma.pointTransaction.findUniqueOrThrow({
     *   where: {
     *     // ... provide filter here
     *   }
     * })
     */
    findUniqueOrThrow<T extends PointTransactionFindUniqueOrThrowArgs>(args: SelectSubset<T, PointTransactionFindUniqueOrThrowArgs<ExtArgs>>): Prisma__PointTransactionClient<$Result.GetResult<Prisma.$PointTransactionPayload<ExtArgs>, T, "findUniqueOrThrow", GlobalOmitOptions>, never, ExtArgs, GlobalOmitOptions>

    /**
     * Find the first PointTransaction that matches the filter.
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * @param {PointTransactionFindFirstArgs} args - Arguments to find a PointTransaction
     * @example
     * // Get one PointTransaction
     * const pointTransaction = await prisma.pointTransaction.findFirst({
     *   where: {
     *     // ... provide filter here
     *   }
     * })
     */
    findFirst<T extends PointTransactionFindFirstArgs>(args?: SelectSubset<T, PointTransactionFindFirstArgs<ExtArgs>>): Prisma__PointTransactionClient<$Result.GetResult<Prisma.$PointTransactionPayload<ExtArgs>, T, "findFirst", GlobalOmitOptions> | null, null, ExtArgs, GlobalOmitOptions>

    /**
     * Find the first PointTransaction that matches the filter or
     * throw `PrismaKnownClientError` with `P2025` code if no matches were found.
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * @param {PointTransactionFindFirstOrThrowArgs} args - Arguments to find a PointTransaction
     * @example
     * // Get one PointTransaction
     * const pointTransaction = await prisma.pointTransaction.findFirstOrThrow({
     *   where: {
     *     // ... provide filter here
     *   }
     * })
     */
    findFirstOrThrow<T extends PointTransactionFindFirstOrThrowArgs>(args?: SelectSubset<T, PointTransactionFindFirstOrThrowArgs<ExtArgs>>): Prisma__PointTransactionClient<$Result.GetResult<Prisma.$PointTransactionPayload<ExtArgs>, T, "findFirstOrThrow", GlobalOmitOptions>, never, ExtArgs, GlobalOmitOptions>

    /**
     * Find zero or more PointTransactions that matches the filter.
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * @param {PointTransactionFindManyArgs} args - Arguments to filter and select certain fields only.
     * @example
     * // Get all PointTransactions
     * const pointTransactions = await prisma.pointTransaction.findMany()
     * 
     * // Get first 10 PointTransactions
     * const pointTransactions = await prisma.pointTransaction.findMany({ take: 10 })
     * 
     * // Only select the `id`
     * const pointTransactionWithIdOnly = await prisma.pointTransaction.findMany({ select: { id: true } })
     * 
     */
    findMany<T extends PointTransactionFindManyArgs>(args?: SelectSubset<T, PointTransactionFindManyArgs<ExtArgs>>): Prisma.PrismaPromise<$Result.GetResult<Prisma.$PointTransactionPayload<ExtArgs>, T, "findMany", GlobalOmitOptions>>

    /**
     * Create a PointTransaction.
     * @param {PointTransactionCreateArgs} args - Arguments to create a PointTransaction.
     * @example
     * // Create one PointTransaction
     * const PointTransaction = await prisma.pointTransaction.create({
     *   data: {
     *     // ... data to create a PointTransaction
     *   }
     * })
     * 
     */
    create<T extends PointTransactionCreateArgs>(args: SelectSubset<T, PointTransactionCreateArgs<ExtArgs>>): Prisma__PointTransactionClient<$Result.GetResult<Prisma.$PointTransactionPayload<ExtArgs>, T, "create", GlobalOmitOptions>, never, ExtArgs, GlobalOmitOptions>

    /**
     * Create many PointTransactions.
     * @param {PointTransactionCreateManyArgs} args - Arguments to create many PointTransactions.
     * @example
     * // Create many PointTransactions
     * const pointTransaction = await prisma.pointTransaction.createMany({
     *   data: [
     *     // ... provide data here
     *   ]
     * })
     *     
     */
    createMany<T extends PointTransactionCreateManyArgs>(args?: SelectSubset<T, PointTransactionCreateManyArgs<ExtArgs>>): Prisma.PrismaPromise<BatchPayload>

    /**
     * Create many PointTransactions and returns the data saved in the database.
     * @param {PointTransactionCreateManyAndReturnArgs} args - Arguments to create many PointTransactions.
     * @example
     * // Create many PointTransactions
     * const pointTransaction = await prisma.pointTransaction.createManyAndReturn({
     *   data: [
     *     // ... provide data here
     *   ]
     * })
     * 
     * // Create many PointTransactions and only return the `id`
     * const pointTransactionWithIdOnly = await prisma.pointTransaction.createManyAndReturn({
     *   select: { id: true },
     *   data: [
     *     // ... provide data here
     *   ]
     * })
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * 
     */
    createManyAndReturn<T extends PointTransactionCreateManyAndReturnArgs>(args?: SelectSubset<T, PointTransactionCreateManyAndReturnArgs<ExtArgs>>): Prisma.PrismaPromise<$Result.GetResult<Prisma.$PointTransactionPayload<ExtArgs>, T, "createManyAndReturn", GlobalOmitOptions>>

    /**
     * Delete a PointTransaction.
     * @param {PointTransactionDeleteArgs} args - Arguments to delete one PointTransaction.
     * @example
     * // Delete one PointTransaction
     * const PointTransaction = await prisma.pointTransaction.delete({
     *   where: {
     *     // ... filter to delete one PointTransaction
     *   }
     * })
     * 
     */
    delete<T extends PointTransactionDeleteArgs>(args: SelectSubset<T, PointTransactionDeleteArgs<ExtArgs>>): Prisma__PointTransactionClient<$Result.GetResult<Prisma.$PointTransactionPayload<ExtArgs>, T, "delete", GlobalOmitOptions>, never, ExtArgs, GlobalOmitOptions>

    /**
     * Update one PointTransaction.
     * @param {PointTransactionUpdateArgs} args - Arguments to update one PointTransaction.
     * @example
     * // Update one PointTransaction
     * const pointTransaction = await prisma.pointTransaction.update({
     *   where: {
     *     // ... provide filter here
     *   },
     *   data: {
     *     // ... provide data here
     *   }
     * })
     * 
     */
    update<T extends PointTransactionUpdateArgs>(args: SelectSubset<T, PointTransactionUpdateArgs<ExtArgs>>): Prisma__PointTransactionClient<$Result.GetResult<Prisma.$PointTransactionPayload<ExtArgs>, T, "update", GlobalOmitOptions>, never, ExtArgs, GlobalOmitOptions>

    /**
     * Delete zero or more PointTransactions.
     * @param {PointTransactionDeleteManyArgs} args - Arguments to filter PointTransactions to delete.
     * @example
     * // Delete a few PointTransactions
     * const { count } = await prisma.pointTransaction.deleteMany({
     *   where: {
     *     // ... provide filter here
     *   }
     * })
     * 
     */
    deleteMany<T extends PointTransactionDeleteManyArgs>(args?: SelectSubset<T, PointTransactionDeleteManyArgs<ExtArgs>>): Prisma.PrismaPromise<BatchPayload>

    /**
     * Update zero or more PointTransactions.
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * @param {PointTransactionUpdateManyArgs} args - Arguments to update one or more rows.
     * @example
     * // Update many PointTransactions
     * const pointTransaction = await prisma.pointTransaction.updateMany({
     *   where: {
     *     // ... provide filter here
     *   },
     *   data: {
     *     // ... provide data here
     *   }
     * })
     * 
     */
    updateMany<T extends PointTransactionUpdateManyArgs>(args: SelectSubset<T, PointTransactionUpdateManyArgs<ExtArgs>>): Prisma.PrismaPromise<BatchPayload>

    /**
     * Update zero or more PointTransactions and returns the data updated in the database.
     * @param {PointTransactionUpdateManyAndReturnArgs} args - Arguments to update many PointTransactions.
     * @example
     * // Update many PointTransactions
     * const pointTransaction = await prisma.pointTransaction.updateManyAndReturn({
     *   where: {
     *     // ... provide filter here
     *   },
     *   data: [
     *     // ... provide data here
     *   ]
     * })
     * 
     * // Update zero or more PointTransactions and only return the `id`
     * const pointTransactionWithIdOnly = await prisma.pointTransaction.updateManyAndReturn({
     *   select: { id: true },
     *   where: {
     *     // ... provide filter here
     *   },
     *   data: [
     *     // ... provide data here
     *   ]
     * })
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * 
     */
    updateManyAndReturn<T extends PointTransactionUpdateManyAndReturnArgs>(args: SelectSubset<T, PointTransactionUpdateManyAndReturnArgs<ExtArgs>>): Prisma.PrismaPromise<$Result.GetResult<Prisma.$PointTransactionPayload<ExtArgs>, T, "updateManyAndReturn", GlobalOmitOptions>>

    /**
     * Create or update one PointTransaction.
     * @param {PointTransactionUpsertArgs} args - Arguments to update or create a PointTransaction.
     * @example
     * // Update or create a PointTransaction
     * const pointTransaction = await prisma.pointTransaction.upsert({
     *   create: {
     *     // ... data to create a PointTransaction
     *   },
     *   update: {
     *     // ... in case it already exists, update
     *   },
     *   where: {
     *     // ... the filter for the PointTransaction we want to update
     *   }
     * })
     */
    upsert<T extends PointTransactionUpsertArgs>(args: SelectSubset<T, PointTransactionUpsertArgs<ExtArgs>>): Prisma__PointTransactionClient<$Result.GetResult<Prisma.$PointTransactionPayload<ExtArgs>, T, "upsert", GlobalOmitOptions>, never, ExtArgs, GlobalOmitOptions>


    /**
     * Count the number of PointTransactions.
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * @param {PointTransactionCountArgs} args - Arguments to filter PointTransactions to count.
     * @example
     * // Count the number of PointTransactions
     * const count = await prisma.pointTransaction.count({
     *   where: {
     *     // ... the filter for the PointTransactions we want to count
     *   }
     * })
    **/
    count<T extends PointTransactionCountArgs>(
      args?: Subset<T, PointTransactionCountArgs>,
    ): Prisma.PrismaPromise<
      T extends $Utils.Record<'select', any>
        ? T['select'] extends true
          ? number
          : GetScalarType<T['select'], PointTransactionCountAggregateOutputType>
        : number
    >

    /**
     * Allows you to perform aggregations operations on a PointTransaction.
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * @param {PointTransactionAggregateArgs} args - Select which aggregations you would like to apply and on what fields.
     * @example
     * // Ordered by age ascending
     * // Where email contains prisma.io
     * // Limited to the 10 users
     * const aggregations = await prisma.user.aggregate({
     *   _avg: {
     *     age: true,
     *   },
     *   where: {
     *     email: {
     *       contains: "prisma.io",
     *     },
     *   },
     *   orderBy: {
     *     age: "asc",
     *   },
     *   take: 10,
     * })
    **/
    aggregate<T extends PointTransactionAggregateArgs>(args: Subset<T, PointTransactionAggregateArgs>): Prisma.PrismaPromise<GetPointTransactionAggregateType<T>>

    /**
     * Group by PointTransaction.
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * @param {PointTransactionGroupByArgs} args - Group by arguments.
     * @example
     * // Group by city, order by createdAt, get count
     * const result = await prisma.user.groupBy({
     *   by: ['city', 'createdAt'],
     *   orderBy: {
     *     createdAt: true
     *   },
     *   _count: {
     *     _all: true
     *   },
     * })
     * 
    **/
    groupBy<
      T extends PointTransactionGroupByArgs,
      HasSelectOrTake extends Or<
        Extends<'skip', Keys<T>>,
        Extends<'take', Keys<T>>
      >,
      OrderByArg extends True extends HasSelectOrTake
        ? { orderBy: PointTransactionGroupByArgs['orderBy'] }
        : { orderBy?: PointTransactionGroupByArgs['orderBy'] },
      OrderFields extends ExcludeUnderscoreKeys<Keys<MaybeTupleToUnion<T['orderBy']>>>,
      ByFields extends MaybeTupleToUnion<T['by']>,
      ByValid extends Has<ByFields, OrderFields>,
      HavingFields extends GetHavingFields<T['having']>,
      HavingValid extends Has<ByFields, HavingFields>,
      ByEmpty extends T['by'] extends never[] ? True : False,
      InputErrors extends ByEmpty extends True
      ? `Error: "by" must not be empty.`
      : HavingValid extends False
      ? {
          [P in HavingFields]: P extends ByFields
            ? never
            : P extends string
            ? `Error: Field "${P}" used in "having" needs to be provided in "by".`
            : [
                Error,
                'Field ',
                P,
                ` in "having" needs to be provided in "by"`,
              ]
        }[HavingFields]
      : 'take' extends Keys<T>
      ? 'orderBy' extends Keys<T>
        ? ByValid extends True
          ? {}
          : {
              [P in OrderFields]: P extends ByFields
                ? never
                : `Error: Field "${P}" in "orderBy" needs to be provided in "by"`
            }[OrderFields]
        : 'Error: If you provide "take", you also need to provide "orderBy"'
      : 'skip' extends Keys<T>
      ? 'orderBy' extends Keys<T>
        ? ByValid extends True
          ? {}
          : {
              [P in OrderFields]: P extends ByFields
                ? never
                : `Error: Field "${P}" in "orderBy" needs to be provided in "by"`
            }[OrderFields]
        : 'Error: If you provide "skip", you also need to provide "orderBy"'
      : ByValid extends True
      ? {}
      : {
          [P in OrderFields]: P extends ByFields
            ? never
            : `Error: Field "${P}" in "orderBy" needs to be provided in "by"`
        }[OrderFields]
    >(args: SubsetIntersection<T, PointTransactionGroupByArgs, OrderByArg> & InputErrors): {} extends InputErrors ? GetPointTransactionGroupByPayload<T> : Prisma.PrismaPromise<InputErrors>
  /**
   * Fields of the PointTransaction model
   */
  readonly fields: PointTransactionFieldRefs;
  }

  /**
   * The delegate class that acts as a "Promise-like" for PointTransaction.
   * Why is this prefixed with `Prisma__`?
   * Because we want to prevent naming conflicts as mentioned in
   * https://github.com/prisma/prisma-client-js/issues/707
   */
  export interface Prisma__PointTransactionClient<T, Null = never, ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs, GlobalOmitOptions = {}> extends Prisma.PrismaPromise<T> {
    readonly [Symbol.toStringTag]: "PrismaPromise"
    user<T extends UserDefaultArgs<ExtArgs> = {}>(args?: Subset<T, UserDefaultArgs<ExtArgs>>): Prisma__UserClient<$Result.GetResult<Prisma.$UserPayload<ExtArgs>, T, "findUniqueOrThrow", GlobalOmitOptions> | Null, Null, ExtArgs, GlobalOmitOptions>
    /**
     * Attaches callbacks for the resolution and/or rejection of the Promise.
     * @param onfulfilled The callback to execute when the Promise is resolved.
     * @param onrejected The callback to execute when the Promise is rejected.
     * @returns A Promise for the completion of which ever callback is executed.
     */
    then<TResult1 = T, TResult2 = never>(onfulfilled?: ((value: T) => TResult1 | PromiseLike<TResult1>) | undefined | null, onrejected?: ((reason: any) => TResult2 | PromiseLike<TResult2>) | undefined | null): $Utils.JsPromise<TResult1 | TResult2>
    /**
     * Attaches a callback for only the rejection of the Promise.
     * @param onrejected The callback to execute when the Promise is rejected.
     * @returns A Promise for the completion of the callback.
     */
    catch<TResult = never>(onrejected?: ((reason: any) => TResult | PromiseLike<TResult>) | undefined | null): $Utils.JsPromise<T | TResult>
    /**
     * Attaches a callback that is invoked when the Promise is settled (fulfilled or rejected). The
     * resolved value cannot be modified from the callback.
     * @param onfinally The callback to execute when the Promise is settled (fulfilled or rejected).
     * @returns A Promise for the completion of the callback.
     */
    finally(onfinally?: (() => void) | undefined | null): $Utils.JsPromise<T>
  }




  /**
   * Fields of the PointTransaction model
   */
  interface PointTransactionFieldRefs {
    readonly id: FieldRef<"PointTransaction", 'String'>
    readonly createdAt: FieldRef<"PointTransaction", 'DateTime'>
    readonly userId: FieldRef<"PointTransaction", 'String'>
    readonly delta: FieldRef<"PointTransaction", 'Int'>
    readonly balanceAfter: FieldRef<"PointTransaction", 'Int'>
    readonly reasonCode: FieldRef<"PointTransaction", 'String'>
    readonly referenceType: FieldRef<"PointTransaction", 'String'>
    readonly referenceId: FieldRef<"PointTransaction", 'String'>
    readonly metadata: FieldRef<"PointTransaction", 'Json'>
  }
    

  // Custom InputTypes
  /**
   * PointTransaction findUnique
   */
  export type PointTransactionFindUniqueArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the PointTransaction
     */
    select?: PointTransactionSelect<ExtArgs> | null
    /**
     * Omit specific fields from the PointTransaction
     */
    omit?: PointTransactionOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: PointTransactionInclude<ExtArgs> | null
    /**
     * Filter, which PointTransaction to fetch.
     */
    where: PointTransactionWhereUniqueInput
  }

  /**
   * PointTransaction findUniqueOrThrow
   */
  export type PointTransactionFindUniqueOrThrowArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the PointTransaction
     */
    select?: PointTransactionSelect<ExtArgs> | null
    /**
     * Omit specific fields from the PointTransaction
     */
    omit?: PointTransactionOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: PointTransactionInclude<ExtArgs> | null
    /**
     * Filter, which PointTransaction to fetch.
     */
    where: PointTransactionWhereUniqueInput
  }

  /**
   * PointTransaction findFirst
   */
  export type PointTransactionFindFirstArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the PointTransaction
     */
    select?: PointTransactionSelect<ExtArgs> | null
    /**
     * Omit specific fields from the PointTransaction
     */
    omit?: PointTransactionOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: PointTransactionInclude<ExtArgs> | null
    /**
     * Filter, which PointTransaction to fetch.
     */
    where?: PointTransactionWhereInput
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/sorting Sorting Docs}
     * 
     * Determine the order of PointTransactions to fetch.
     */
    orderBy?: PointTransactionOrderByWithRelationInput | PointTransactionOrderByWithRelationInput[]
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination#cursor-based-pagination Cursor Docs}
     * 
     * Sets the position for searching for PointTransactions.
     */
    cursor?: PointTransactionWhereUniqueInput
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination Pagination Docs}
     * 
     * Take `±n` PointTransactions from the position of the cursor.
     */
    take?: number
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination Pagination Docs}
     * 
     * Skip the first `n` PointTransactions.
     */
    skip?: number
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/distinct Distinct Docs}
     * 
     * Filter by unique combinations of PointTransactions.
     */
    distinct?: PointTransactionScalarFieldEnum | PointTransactionScalarFieldEnum[]
  }

  /**
   * PointTransaction findFirstOrThrow
   */
  export type PointTransactionFindFirstOrThrowArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the PointTransaction
     */
    select?: PointTransactionSelect<ExtArgs> | null
    /**
     * Omit specific fields from the PointTransaction
     */
    omit?: PointTransactionOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: PointTransactionInclude<ExtArgs> | null
    /**
     * Filter, which PointTransaction to fetch.
     */
    where?: PointTransactionWhereInput
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/sorting Sorting Docs}
     * 
     * Determine the order of PointTransactions to fetch.
     */
    orderBy?: PointTransactionOrderByWithRelationInput | PointTransactionOrderByWithRelationInput[]
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination#cursor-based-pagination Cursor Docs}
     * 
     * Sets the position for searching for PointTransactions.
     */
    cursor?: PointTransactionWhereUniqueInput
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination Pagination Docs}
     * 
     * Take `±n` PointTransactions from the position of the cursor.
     */
    take?: number
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination Pagination Docs}
     * 
     * Skip the first `n` PointTransactions.
     */
    skip?: number
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/distinct Distinct Docs}
     * 
     * Filter by unique combinations of PointTransactions.
     */
    distinct?: PointTransactionScalarFieldEnum | PointTransactionScalarFieldEnum[]
  }

  /**
   * PointTransaction findMany
   */
  export type PointTransactionFindManyArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the PointTransaction
     */
    select?: PointTransactionSelect<ExtArgs> | null
    /**
     * Omit specific fields from the PointTransaction
     */
    omit?: PointTransactionOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: PointTransactionInclude<ExtArgs> | null
    /**
     * Filter, which PointTransactions to fetch.
     */
    where?: PointTransactionWhereInput
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/sorting Sorting Docs}
     * 
     * Determine the order of PointTransactions to fetch.
     */
    orderBy?: PointTransactionOrderByWithRelationInput | PointTransactionOrderByWithRelationInput[]
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination#cursor-based-pagination Cursor Docs}
     * 
     * Sets the position for listing PointTransactions.
     */
    cursor?: PointTransactionWhereUniqueInput
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination Pagination Docs}
     * 
     * Take `±n` PointTransactions from the position of the cursor.
     */
    take?: number
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination Pagination Docs}
     * 
     * Skip the first `n` PointTransactions.
     */
    skip?: number
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/distinct Distinct Docs}
     * 
     * Filter by unique combinations of PointTransactions.
     */
    distinct?: PointTransactionScalarFieldEnum | PointTransactionScalarFieldEnum[]
  }

  /**
   * PointTransaction create
   */
  export type PointTransactionCreateArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the PointTransaction
     */
    select?: PointTransactionSelect<ExtArgs> | null
    /**
     * Omit specific fields from the PointTransaction
     */
    omit?: PointTransactionOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: PointTransactionInclude<ExtArgs> | null
    /**
     * The data needed to create a PointTransaction.
     */
    data: XOR<PointTransactionCreateInput, PointTransactionUncheckedCreateInput>
  }

  /**
   * PointTransaction createMany
   */
  export type PointTransactionCreateManyArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * The data used to create many PointTransactions.
     */
    data: PointTransactionCreateManyInput | PointTransactionCreateManyInput[]
    skipDuplicates?: boolean
  }

  /**
   * PointTransaction createManyAndReturn
   */
  export type PointTransactionCreateManyAndReturnArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the PointTransaction
     */
    select?: PointTransactionSelectCreateManyAndReturn<ExtArgs> | null
    /**
     * Omit specific fields from the PointTransaction
     */
    omit?: PointTransactionOmit<ExtArgs> | null
    /**
     * The data used to create many PointTransactions.
     */
    data: PointTransactionCreateManyInput | PointTransactionCreateManyInput[]
    skipDuplicates?: boolean
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: PointTransactionIncludeCreateManyAndReturn<ExtArgs> | null
  }

  /**
   * PointTransaction update
   */
  export type PointTransactionUpdateArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the PointTransaction
     */
    select?: PointTransactionSelect<ExtArgs> | null
    /**
     * Omit specific fields from the PointTransaction
     */
    omit?: PointTransactionOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: PointTransactionInclude<ExtArgs> | null
    /**
     * The data needed to update a PointTransaction.
     */
    data: XOR<PointTransactionUpdateInput, PointTransactionUncheckedUpdateInput>
    /**
     * Choose, which PointTransaction to update.
     */
    where: PointTransactionWhereUniqueInput
  }

  /**
   * PointTransaction updateMany
   */
  export type PointTransactionUpdateManyArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * The data used to update PointTransactions.
     */
    data: XOR<PointTransactionUpdateManyMutationInput, PointTransactionUncheckedUpdateManyInput>
    /**
     * Filter which PointTransactions to update
     */
    where?: PointTransactionWhereInput
    /**
     * Limit how many PointTransactions to update.
     */
    limit?: number
  }

  /**
   * PointTransaction updateManyAndReturn
   */
  export type PointTransactionUpdateManyAndReturnArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the PointTransaction
     */
    select?: PointTransactionSelectUpdateManyAndReturn<ExtArgs> | null
    /**
     * Omit specific fields from the PointTransaction
     */
    omit?: PointTransactionOmit<ExtArgs> | null
    /**
     * The data used to update PointTransactions.
     */
    data: XOR<PointTransactionUpdateManyMutationInput, PointTransactionUncheckedUpdateManyInput>
    /**
     * Filter which PointTransactions to update
     */
    where?: PointTransactionWhereInput
    /**
     * Limit how many PointTransactions to update.
     */
    limit?: number
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: PointTransactionIncludeUpdateManyAndReturn<ExtArgs> | null
  }

  /**
   * PointTransaction upsert
   */
  export type PointTransactionUpsertArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the PointTransaction
     */
    select?: PointTransactionSelect<ExtArgs> | null
    /**
     * Omit specific fields from the PointTransaction
     */
    omit?: PointTransactionOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: PointTransactionInclude<ExtArgs> | null
    /**
     * The filter to search for the PointTransaction to update in case it exists.
     */
    where: PointTransactionWhereUniqueInput
    /**
     * In case the PointTransaction found by the `where` argument doesn't exist, create a new PointTransaction with this data.
     */
    create: XOR<PointTransactionCreateInput, PointTransactionUncheckedCreateInput>
    /**
     * In case the PointTransaction was found with the provided `where` argument, update it with this data.
     */
    update: XOR<PointTransactionUpdateInput, PointTransactionUncheckedUpdateInput>
  }

  /**
   * PointTransaction delete
   */
  export type PointTransactionDeleteArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the PointTransaction
     */
    select?: PointTransactionSelect<ExtArgs> | null
    /**
     * Omit specific fields from the PointTransaction
     */
    omit?: PointTransactionOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: PointTransactionInclude<ExtArgs> | null
    /**
     * Filter which PointTransaction to delete.
     */
    where: PointTransactionWhereUniqueInput
  }

  /**
   * PointTransaction deleteMany
   */
  export type PointTransactionDeleteManyArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Filter which PointTransactions to delete
     */
    where?: PointTransactionWhereInput
    /**
     * Limit how many PointTransactions to delete.
     */
    limit?: number
  }

  /**
   * PointTransaction without action
   */
  export type PointTransactionDefaultArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the PointTransaction
     */
    select?: PointTransactionSelect<ExtArgs> | null
    /**
     * Omit specific fields from the PointTransaction
     */
    omit?: PointTransactionOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: PointTransactionInclude<ExtArgs> | null
  }


  /**
   * Model Site
   */

  export type AggregateSite = {
    _count: SiteCountAggregateOutputType | null
    _avg: SiteAvgAggregateOutputType | null
    _sum: SiteSumAggregateOutputType | null
    _min: SiteMinAggregateOutputType | null
    _max: SiteMaxAggregateOutputType | null
  }

  export type SiteAvgAggregateOutputType = {
    latitude: number | null
    longitude: number | null
  }

  export type SiteSumAggregateOutputType = {
    latitude: number | null
    longitude: number | null
  }

  export type SiteMinAggregateOutputType = {
    id: string | null
    createdAt: Date | null
    updatedAt: Date | null
    latitude: number | null
    longitude: number | null
    description: string | null
    status: $Enums.SiteStatus | null
  }

  export type SiteMaxAggregateOutputType = {
    id: string | null
    createdAt: Date | null
    updatedAt: Date | null
    latitude: number | null
    longitude: number | null
    description: string | null
    status: $Enums.SiteStatus | null
  }

  export type SiteCountAggregateOutputType = {
    id: number
    createdAt: number
    updatedAt: number
    latitude: number
    longitude: number
    description: number
    status: number
    _all: number
  }


  export type SiteAvgAggregateInputType = {
    latitude?: true
    longitude?: true
  }

  export type SiteSumAggregateInputType = {
    latitude?: true
    longitude?: true
  }

  export type SiteMinAggregateInputType = {
    id?: true
    createdAt?: true
    updatedAt?: true
    latitude?: true
    longitude?: true
    description?: true
    status?: true
  }

  export type SiteMaxAggregateInputType = {
    id?: true
    createdAt?: true
    updatedAt?: true
    latitude?: true
    longitude?: true
    description?: true
    status?: true
  }

  export type SiteCountAggregateInputType = {
    id?: true
    createdAt?: true
    updatedAt?: true
    latitude?: true
    longitude?: true
    description?: true
    status?: true
    _all?: true
  }

  export type SiteAggregateArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Filter which Site to aggregate.
     */
    where?: SiteWhereInput
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/sorting Sorting Docs}
     * 
     * Determine the order of Sites to fetch.
     */
    orderBy?: SiteOrderByWithRelationInput | SiteOrderByWithRelationInput[]
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination#cursor-based-pagination Cursor Docs}
     * 
     * Sets the start position
     */
    cursor?: SiteWhereUniqueInput
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination Pagination Docs}
     * 
     * Take `±n` Sites from the position of the cursor.
     */
    take?: number
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination Pagination Docs}
     * 
     * Skip the first `n` Sites.
     */
    skip?: number
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/aggregations Aggregation Docs}
     * 
     * Count returned Sites
    **/
    _count?: true | SiteCountAggregateInputType
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/aggregations Aggregation Docs}
     * 
     * Select which fields to average
    **/
    _avg?: SiteAvgAggregateInputType
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/aggregations Aggregation Docs}
     * 
     * Select which fields to sum
    **/
    _sum?: SiteSumAggregateInputType
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/aggregations Aggregation Docs}
     * 
     * Select which fields to find the minimum value
    **/
    _min?: SiteMinAggregateInputType
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/aggregations Aggregation Docs}
     * 
     * Select which fields to find the maximum value
    **/
    _max?: SiteMaxAggregateInputType
  }

  export type GetSiteAggregateType<T extends SiteAggregateArgs> = {
        [P in keyof T & keyof AggregateSite]: P extends '_count' | 'count'
      ? T[P] extends true
        ? number
        : GetScalarType<T[P], AggregateSite[P]>
      : GetScalarType<T[P], AggregateSite[P]>
  }




  export type SiteGroupByArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    where?: SiteWhereInput
    orderBy?: SiteOrderByWithAggregationInput | SiteOrderByWithAggregationInput[]
    by: SiteScalarFieldEnum[] | SiteScalarFieldEnum
    having?: SiteScalarWhereWithAggregatesInput
    take?: number
    skip?: number
    _count?: SiteCountAggregateInputType | true
    _avg?: SiteAvgAggregateInputType
    _sum?: SiteSumAggregateInputType
    _min?: SiteMinAggregateInputType
    _max?: SiteMaxAggregateInputType
  }

  export type SiteGroupByOutputType = {
    id: string
    createdAt: Date
    updatedAt: Date
    latitude: number
    longitude: number
    description: string | null
    status: $Enums.SiteStatus
    _count: SiteCountAggregateOutputType | null
    _avg: SiteAvgAggregateOutputType | null
    _sum: SiteSumAggregateOutputType | null
    _min: SiteMinAggregateOutputType | null
    _max: SiteMaxAggregateOutputType | null
  }

  type GetSiteGroupByPayload<T extends SiteGroupByArgs> = Prisma.PrismaPromise<
    Array<
      PickEnumerable<SiteGroupByOutputType, T['by']> &
        {
          [P in ((keyof T) & (keyof SiteGroupByOutputType))]: P extends '_count'
            ? T[P] extends boolean
              ? number
              : GetScalarType<T[P], SiteGroupByOutputType[P]>
            : GetScalarType<T[P], SiteGroupByOutputType[P]>
        }
      >
    >


  export type SiteSelect<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = $Extensions.GetSelect<{
    id?: boolean
    createdAt?: boolean
    updatedAt?: boolean
    latitude?: boolean
    longitude?: boolean
    description?: boolean
    status?: boolean
    reports?: boolean | Site$reportsArgs<ExtArgs>
    events?: boolean | Site$eventsArgs<ExtArgs>
    _count?: boolean | SiteCountOutputTypeDefaultArgs<ExtArgs>
  }, ExtArgs["result"]["site"]>

  export type SiteSelectCreateManyAndReturn<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = $Extensions.GetSelect<{
    id?: boolean
    createdAt?: boolean
    updatedAt?: boolean
    latitude?: boolean
    longitude?: boolean
    description?: boolean
    status?: boolean
  }, ExtArgs["result"]["site"]>

  export type SiteSelectUpdateManyAndReturn<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = $Extensions.GetSelect<{
    id?: boolean
    createdAt?: boolean
    updatedAt?: boolean
    latitude?: boolean
    longitude?: boolean
    description?: boolean
    status?: boolean
  }, ExtArgs["result"]["site"]>

  export type SiteSelectScalar = {
    id?: boolean
    createdAt?: boolean
    updatedAt?: boolean
    latitude?: boolean
    longitude?: boolean
    description?: boolean
    status?: boolean
  }

  export type SiteOmit<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = $Extensions.GetOmit<"id" | "createdAt" | "updatedAt" | "latitude" | "longitude" | "description" | "status", ExtArgs["result"]["site"]>
  export type SiteInclude<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    reports?: boolean | Site$reportsArgs<ExtArgs>
    events?: boolean | Site$eventsArgs<ExtArgs>
    _count?: boolean | SiteCountOutputTypeDefaultArgs<ExtArgs>
  }
  export type SiteIncludeCreateManyAndReturn<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {}
  export type SiteIncludeUpdateManyAndReturn<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {}

  export type $SitePayload<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    name: "Site"
    objects: {
      reports: Prisma.$ReportPayload<ExtArgs>[]
      events: Prisma.$CleanupEventPayload<ExtArgs>[]
    }
    scalars: $Extensions.GetPayloadResult<{
      id: string
      createdAt: Date
      updatedAt: Date
      latitude: number
      longitude: number
      description: string | null
      status: $Enums.SiteStatus
    }, ExtArgs["result"]["site"]>
    composites: {}
  }

  type SiteGetPayload<S extends boolean | null | undefined | SiteDefaultArgs> = $Result.GetResult<Prisma.$SitePayload, S>

  type SiteCountArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> =
    Omit<SiteFindManyArgs, 'select' | 'include' | 'distinct' | 'omit'> & {
      select?: SiteCountAggregateInputType | true
    }

  export interface SiteDelegate<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs, GlobalOmitOptions = {}> {
    [K: symbol]: { types: Prisma.TypeMap<ExtArgs>['model']['Site'], meta: { name: 'Site' } }
    /**
     * Find zero or one Site that matches the filter.
     * @param {SiteFindUniqueArgs} args - Arguments to find a Site
     * @example
     * // Get one Site
     * const site = await prisma.site.findUnique({
     *   where: {
     *     // ... provide filter here
     *   }
     * })
     */
    findUnique<T extends SiteFindUniqueArgs>(args: SelectSubset<T, SiteFindUniqueArgs<ExtArgs>>): Prisma__SiteClient<$Result.GetResult<Prisma.$SitePayload<ExtArgs>, T, "findUnique", GlobalOmitOptions> | null, null, ExtArgs, GlobalOmitOptions>

    /**
     * Find one Site that matches the filter or throw an error with `error.code='P2025'`
     * if no matches were found.
     * @param {SiteFindUniqueOrThrowArgs} args - Arguments to find a Site
     * @example
     * // Get one Site
     * const site = await prisma.site.findUniqueOrThrow({
     *   where: {
     *     // ... provide filter here
     *   }
     * })
     */
    findUniqueOrThrow<T extends SiteFindUniqueOrThrowArgs>(args: SelectSubset<T, SiteFindUniqueOrThrowArgs<ExtArgs>>): Prisma__SiteClient<$Result.GetResult<Prisma.$SitePayload<ExtArgs>, T, "findUniqueOrThrow", GlobalOmitOptions>, never, ExtArgs, GlobalOmitOptions>

    /**
     * Find the first Site that matches the filter.
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * @param {SiteFindFirstArgs} args - Arguments to find a Site
     * @example
     * // Get one Site
     * const site = await prisma.site.findFirst({
     *   where: {
     *     // ... provide filter here
     *   }
     * })
     */
    findFirst<T extends SiteFindFirstArgs>(args?: SelectSubset<T, SiteFindFirstArgs<ExtArgs>>): Prisma__SiteClient<$Result.GetResult<Prisma.$SitePayload<ExtArgs>, T, "findFirst", GlobalOmitOptions> | null, null, ExtArgs, GlobalOmitOptions>

    /**
     * Find the first Site that matches the filter or
     * throw `PrismaKnownClientError` with `P2025` code if no matches were found.
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * @param {SiteFindFirstOrThrowArgs} args - Arguments to find a Site
     * @example
     * // Get one Site
     * const site = await prisma.site.findFirstOrThrow({
     *   where: {
     *     // ... provide filter here
     *   }
     * })
     */
    findFirstOrThrow<T extends SiteFindFirstOrThrowArgs>(args?: SelectSubset<T, SiteFindFirstOrThrowArgs<ExtArgs>>): Prisma__SiteClient<$Result.GetResult<Prisma.$SitePayload<ExtArgs>, T, "findFirstOrThrow", GlobalOmitOptions>, never, ExtArgs, GlobalOmitOptions>

    /**
     * Find zero or more Sites that matches the filter.
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * @param {SiteFindManyArgs} args - Arguments to filter and select certain fields only.
     * @example
     * // Get all Sites
     * const sites = await prisma.site.findMany()
     * 
     * // Get first 10 Sites
     * const sites = await prisma.site.findMany({ take: 10 })
     * 
     * // Only select the `id`
     * const siteWithIdOnly = await prisma.site.findMany({ select: { id: true } })
     * 
     */
    findMany<T extends SiteFindManyArgs>(args?: SelectSubset<T, SiteFindManyArgs<ExtArgs>>): Prisma.PrismaPromise<$Result.GetResult<Prisma.$SitePayload<ExtArgs>, T, "findMany", GlobalOmitOptions>>

    /**
     * Create a Site.
     * @param {SiteCreateArgs} args - Arguments to create a Site.
     * @example
     * // Create one Site
     * const Site = await prisma.site.create({
     *   data: {
     *     // ... data to create a Site
     *   }
     * })
     * 
     */
    create<T extends SiteCreateArgs>(args: SelectSubset<T, SiteCreateArgs<ExtArgs>>): Prisma__SiteClient<$Result.GetResult<Prisma.$SitePayload<ExtArgs>, T, "create", GlobalOmitOptions>, never, ExtArgs, GlobalOmitOptions>

    /**
     * Create many Sites.
     * @param {SiteCreateManyArgs} args - Arguments to create many Sites.
     * @example
     * // Create many Sites
     * const site = await prisma.site.createMany({
     *   data: [
     *     // ... provide data here
     *   ]
     * })
     *     
     */
    createMany<T extends SiteCreateManyArgs>(args?: SelectSubset<T, SiteCreateManyArgs<ExtArgs>>): Prisma.PrismaPromise<BatchPayload>

    /**
     * Create many Sites and returns the data saved in the database.
     * @param {SiteCreateManyAndReturnArgs} args - Arguments to create many Sites.
     * @example
     * // Create many Sites
     * const site = await prisma.site.createManyAndReturn({
     *   data: [
     *     // ... provide data here
     *   ]
     * })
     * 
     * // Create many Sites and only return the `id`
     * const siteWithIdOnly = await prisma.site.createManyAndReturn({
     *   select: { id: true },
     *   data: [
     *     // ... provide data here
     *   ]
     * })
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * 
     */
    createManyAndReturn<T extends SiteCreateManyAndReturnArgs>(args?: SelectSubset<T, SiteCreateManyAndReturnArgs<ExtArgs>>): Prisma.PrismaPromise<$Result.GetResult<Prisma.$SitePayload<ExtArgs>, T, "createManyAndReturn", GlobalOmitOptions>>

    /**
     * Delete a Site.
     * @param {SiteDeleteArgs} args - Arguments to delete one Site.
     * @example
     * // Delete one Site
     * const Site = await prisma.site.delete({
     *   where: {
     *     // ... filter to delete one Site
     *   }
     * })
     * 
     */
    delete<T extends SiteDeleteArgs>(args: SelectSubset<T, SiteDeleteArgs<ExtArgs>>): Prisma__SiteClient<$Result.GetResult<Prisma.$SitePayload<ExtArgs>, T, "delete", GlobalOmitOptions>, never, ExtArgs, GlobalOmitOptions>

    /**
     * Update one Site.
     * @param {SiteUpdateArgs} args - Arguments to update one Site.
     * @example
     * // Update one Site
     * const site = await prisma.site.update({
     *   where: {
     *     // ... provide filter here
     *   },
     *   data: {
     *     // ... provide data here
     *   }
     * })
     * 
     */
    update<T extends SiteUpdateArgs>(args: SelectSubset<T, SiteUpdateArgs<ExtArgs>>): Prisma__SiteClient<$Result.GetResult<Prisma.$SitePayload<ExtArgs>, T, "update", GlobalOmitOptions>, never, ExtArgs, GlobalOmitOptions>

    /**
     * Delete zero or more Sites.
     * @param {SiteDeleteManyArgs} args - Arguments to filter Sites to delete.
     * @example
     * // Delete a few Sites
     * const { count } = await prisma.site.deleteMany({
     *   where: {
     *     // ... provide filter here
     *   }
     * })
     * 
     */
    deleteMany<T extends SiteDeleteManyArgs>(args?: SelectSubset<T, SiteDeleteManyArgs<ExtArgs>>): Prisma.PrismaPromise<BatchPayload>

    /**
     * Update zero or more Sites.
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * @param {SiteUpdateManyArgs} args - Arguments to update one or more rows.
     * @example
     * // Update many Sites
     * const site = await prisma.site.updateMany({
     *   where: {
     *     // ... provide filter here
     *   },
     *   data: {
     *     // ... provide data here
     *   }
     * })
     * 
     */
    updateMany<T extends SiteUpdateManyArgs>(args: SelectSubset<T, SiteUpdateManyArgs<ExtArgs>>): Prisma.PrismaPromise<BatchPayload>

    /**
     * Update zero or more Sites and returns the data updated in the database.
     * @param {SiteUpdateManyAndReturnArgs} args - Arguments to update many Sites.
     * @example
     * // Update many Sites
     * const site = await prisma.site.updateManyAndReturn({
     *   where: {
     *     // ... provide filter here
     *   },
     *   data: [
     *     // ... provide data here
     *   ]
     * })
     * 
     * // Update zero or more Sites and only return the `id`
     * const siteWithIdOnly = await prisma.site.updateManyAndReturn({
     *   select: { id: true },
     *   where: {
     *     // ... provide filter here
     *   },
     *   data: [
     *     // ... provide data here
     *   ]
     * })
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * 
     */
    updateManyAndReturn<T extends SiteUpdateManyAndReturnArgs>(args: SelectSubset<T, SiteUpdateManyAndReturnArgs<ExtArgs>>): Prisma.PrismaPromise<$Result.GetResult<Prisma.$SitePayload<ExtArgs>, T, "updateManyAndReturn", GlobalOmitOptions>>

    /**
     * Create or update one Site.
     * @param {SiteUpsertArgs} args - Arguments to update or create a Site.
     * @example
     * // Update or create a Site
     * const site = await prisma.site.upsert({
     *   create: {
     *     // ... data to create a Site
     *   },
     *   update: {
     *     // ... in case it already exists, update
     *   },
     *   where: {
     *     // ... the filter for the Site we want to update
     *   }
     * })
     */
    upsert<T extends SiteUpsertArgs>(args: SelectSubset<T, SiteUpsertArgs<ExtArgs>>): Prisma__SiteClient<$Result.GetResult<Prisma.$SitePayload<ExtArgs>, T, "upsert", GlobalOmitOptions>, never, ExtArgs, GlobalOmitOptions>


    /**
     * Count the number of Sites.
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * @param {SiteCountArgs} args - Arguments to filter Sites to count.
     * @example
     * // Count the number of Sites
     * const count = await prisma.site.count({
     *   where: {
     *     // ... the filter for the Sites we want to count
     *   }
     * })
    **/
    count<T extends SiteCountArgs>(
      args?: Subset<T, SiteCountArgs>,
    ): Prisma.PrismaPromise<
      T extends $Utils.Record<'select', any>
        ? T['select'] extends true
          ? number
          : GetScalarType<T['select'], SiteCountAggregateOutputType>
        : number
    >

    /**
     * Allows you to perform aggregations operations on a Site.
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * @param {SiteAggregateArgs} args - Select which aggregations you would like to apply and on what fields.
     * @example
     * // Ordered by age ascending
     * // Where email contains prisma.io
     * // Limited to the 10 users
     * const aggregations = await prisma.user.aggregate({
     *   _avg: {
     *     age: true,
     *   },
     *   where: {
     *     email: {
     *       contains: "prisma.io",
     *     },
     *   },
     *   orderBy: {
     *     age: "asc",
     *   },
     *   take: 10,
     * })
    **/
    aggregate<T extends SiteAggregateArgs>(args: Subset<T, SiteAggregateArgs>): Prisma.PrismaPromise<GetSiteAggregateType<T>>

    /**
     * Group by Site.
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * @param {SiteGroupByArgs} args - Group by arguments.
     * @example
     * // Group by city, order by createdAt, get count
     * const result = await prisma.user.groupBy({
     *   by: ['city', 'createdAt'],
     *   orderBy: {
     *     createdAt: true
     *   },
     *   _count: {
     *     _all: true
     *   },
     * })
     * 
    **/
    groupBy<
      T extends SiteGroupByArgs,
      HasSelectOrTake extends Or<
        Extends<'skip', Keys<T>>,
        Extends<'take', Keys<T>>
      >,
      OrderByArg extends True extends HasSelectOrTake
        ? { orderBy: SiteGroupByArgs['orderBy'] }
        : { orderBy?: SiteGroupByArgs['orderBy'] },
      OrderFields extends ExcludeUnderscoreKeys<Keys<MaybeTupleToUnion<T['orderBy']>>>,
      ByFields extends MaybeTupleToUnion<T['by']>,
      ByValid extends Has<ByFields, OrderFields>,
      HavingFields extends GetHavingFields<T['having']>,
      HavingValid extends Has<ByFields, HavingFields>,
      ByEmpty extends T['by'] extends never[] ? True : False,
      InputErrors extends ByEmpty extends True
      ? `Error: "by" must not be empty.`
      : HavingValid extends False
      ? {
          [P in HavingFields]: P extends ByFields
            ? never
            : P extends string
            ? `Error: Field "${P}" used in "having" needs to be provided in "by".`
            : [
                Error,
                'Field ',
                P,
                ` in "having" needs to be provided in "by"`,
              ]
        }[HavingFields]
      : 'take' extends Keys<T>
      ? 'orderBy' extends Keys<T>
        ? ByValid extends True
          ? {}
          : {
              [P in OrderFields]: P extends ByFields
                ? never
                : `Error: Field "${P}" in "orderBy" needs to be provided in "by"`
            }[OrderFields]
        : 'Error: If you provide "take", you also need to provide "orderBy"'
      : 'skip' extends Keys<T>
      ? 'orderBy' extends Keys<T>
        ? ByValid extends True
          ? {}
          : {
              [P in OrderFields]: P extends ByFields
                ? never
                : `Error: Field "${P}" in "orderBy" needs to be provided in "by"`
            }[OrderFields]
        : 'Error: If you provide "skip", you also need to provide "orderBy"'
      : ByValid extends True
      ? {}
      : {
          [P in OrderFields]: P extends ByFields
            ? never
            : `Error: Field "${P}" in "orderBy" needs to be provided in "by"`
        }[OrderFields]
    >(args: SubsetIntersection<T, SiteGroupByArgs, OrderByArg> & InputErrors): {} extends InputErrors ? GetSiteGroupByPayload<T> : Prisma.PrismaPromise<InputErrors>
  /**
   * Fields of the Site model
   */
  readonly fields: SiteFieldRefs;
  }

  /**
   * The delegate class that acts as a "Promise-like" for Site.
   * Why is this prefixed with `Prisma__`?
   * Because we want to prevent naming conflicts as mentioned in
   * https://github.com/prisma/prisma-client-js/issues/707
   */
  export interface Prisma__SiteClient<T, Null = never, ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs, GlobalOmitOptions = {}> extends Prisma.PrismaPromise<T> {
    readonly [Symbol.toStringTag]: "PrismaPromise"
    reports<T extends Site$reportsArgs<ExtArgs> = {}>(args?: Subset<T, Site$reportsArgs<ExtArgs>>): Prisma.PrismaPromise<$Result.GetResult<Prisma.$ReportPayload<ExtArgs>, T, "findMany", GlobalOmitOptions> | Null>
    events<T extends Site$eventsArgs<ExtArgs> = {}>(args?: Subset<T, Site$eventsArgs<ExtArgs>>): Prisma.PrismaPromise<$Result.GetResult<Prisma.$CleanupEventPayload<ExtArgs>, T, "findMany", GlobalOmitOptions> | Null>
    /**
     * Attaches callbacks for the resolution and/or rejection of the Promise.
     * @param onfulfilled The callback to execute when the Promise is resolved.
     * @param onrejected The callback to execute when the Promise is rejected.
     * @returns A Promise for the completion of which ever callback is executed.
     */
    then<TResult1 = T, TResult2 = never>(onfulfilled?: ((value: T) => TResult1 | PromiseLike<TResult1>) | undefined | null, onrejected?: ((reason: any) => TResult2 | PromiseLike<TResult2>) | undefined | null): $Utils.JsPromise<TResult1 | TResult2>
    /**
     * Attaches a callback for only the rejection of the Promise.
     * @param onrejected The callback to execute when the Promise is rejected.
     * @returns A Promise for the completion of the callback.
     */
    catch<TResult = never>(onrejected?: ((reason: any) => TResult | PromiseLike<TResult>) | undefined | null): $Utils.JsPromise<T | TResult>
    /**
     * Attaches a callback that is invoked when the Promise is settled (fulfilled or rejected). The
     * resolved value cannot be modified from the callback.
     * @param onfinally The callback to execute when the Promise is settled (fulfilled or rejected).
     * @returns A Promise for the completion of the callback.
     */
    finally(onfinally?: (() => void) | undefined | null): $Utils.JsPromise<T>
  }




  /**
   * Fields of the Site model
   */
  interface SiteFieldRefs {
    readonly id: FieldRef<"Site", 'String'>
    readonly createdAt: FieldRef<"Site", 'DateTime'>
    readonly updatedAt: FieldRef<"Site", 'DateTime'>
    readonly latitude: FieldRef<"Site", 'Float'>
    readonly longitude: FieldRef<"Site", 'Float'>
    readonly description: FieldRef<"Site", 'String'>
    readonly status: FieldRef<"Site", 'SiteStatus'>
  }
    

  // Custom InputTypes
  /**
   * Site findUnique
   */
  export type SiteFindUniqueArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the Site
     */
    select?: SiteSelect<ExtArgs> | null
    /**
     * Omit specific fields from the Site
     */
    omit?: SiteOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: SiteInclude<ExtArgs> | null
    /**
     * Filter, which Site to fetch.
     */
    where: SiteWhereUniqueInput
  }

  /**
   * Site findUniqueOrThrow
   */
  export type SiteFindUniqueOrThrowArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the Site
     */
    select?: SiteSelect<ExtArgs> | null
    /**
     * Omit specific fields from the Site
     */
    omit?: SiteOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: SiteInclude<ExtArgs> | null
    /**
     * Filter, which Site to fetch.
     */
    where: SiteWhereUniqueInput
  }

  /**
   * Site findFirst
   */
  export type SiteFindFirstArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the Site
     */
    select?: SiteSelect<ExtArgs> | null
    /**
     * Omit specific fields from the Site
     */
    omit?: SiteOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: SiteInclude<ExtArgs> | null
    /**
     * Filter, which Site to fetch.
     */
    where?: SiteWhereInput
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/sorting Sorting Docs}
     * 
     * Determine the order of Sites to fetch.
     */
    orderBy?: SiteOrderByWithRelationInput | SiteOrderByWithRelationInput[]
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination#cursor-based-pagination Cursor Docs}
     * 
     * Sets the position for searching for Sites.
     */
    cursor?: SiteWhereUniqueInput
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination Pagination Docs}
     * 
     * Take `±n` Sites from the position of the cursor.
     */
    take?: number
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination Pagination Docs}
     * 
     * Skip the first `n` Sites.
     */
    skip?: number
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/distinct Distinct Docs}
     * 
     * Filter by unique combinations of Sites.
     */
    distinct?: SiteScalarFieldEnum | SiteScalarFieldEnum[]
  }

  /**
   * Site findFirstOrThrow
   */
  export type SiteFindFirstOrThrowArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the Site
     */
    select?: SiteSelect<ExtArgs> | null
    /**
     * Omit specific fields from the Site
     */
    omit?: SiteOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: SiteInclude<ExtArgs> | null
    /**
     * Filter, which Site to fetch.
     */
    where?: SiteWhereInput
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/sorting Sorting Docs}
     * 
     * Determine the order of Sites to fetch.
     */
    orderBy?: SiteOrderByWithRelationInput | SiteOrderByWithRelationInput[]
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination#cursor-based-pagination Cursor Docs}
     * 
     * Sets the position for searching for Sites.
     */
    cursor?: SiteWhereUniqueInput
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination Pagination Docs}
     * 
     * Take `±n` Sites from the position of the cursor.
     */
    take?: number
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination Pagination Docs}
     * 
     * Skip the first `n` Sites.
     */
    skip?: number
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/distinct Distinct Docs}
     * 
     * Filter by unique combinations of Sites.
     */
    distinct?: SiteScalarFieldEnum | SiteScalarFieldEnum[]
  }

  /**
   * Site findMany
   */
  export type SiteFindManyArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the Site
     */
    select?: SiteSelect<ExtArgs> | null
    /**
     * Omit specific fields from the Site
     */
    omit?: SiteOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: SiteInclude<ExtArgs> | null
    /**
     * Filter, which Sites to fetch.
     */
    where?: SiteWhereInput
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/sorting Sorting Docs}
     * 
     * Determine the order of Sites to fetch.
     */
    orderBy?: SiteOrderByWithRelationInput | SiteOrderByWithRelationInput[]
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination#cursor-based-pagination Cursor Docs}
     * 
     * Sets the position for listing Sites.
     */
    cursor?: SiteWhereUniqueInput
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination Pagination Docs}
     * 
     * Take `±n` Sites from the position of the cursor.
     */
    take?: number
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination Pagination Docs}
     * 
     * Skip the first `n` Sites.
     */
    skip?: number
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/distinct Distinct Docs}
     * 
     * Filter by unique combinations of Sites.
     */
    distinct?: SiteScalarFieldEnum | SiteScalarFieldEnum[]
  }

  /**
   * Site create
   */
  export type SiteCreateArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the Site
     */
    select?: SiteSelect<ExtArgs> | null
    /**
     * Omit specific fields from the Site
     */
    omit?: SiteOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: SiteInclude<ExtArgs> | null
    /**
     * The data needed to create a Site.
     */
    data: XOR<SiteCreateInput, SiteUncheckedCreateInput>
  }

  /**
   * Site createMany
   */
  export type SiteCreateManyArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * The data used to create many Sites.
     */
    data: SiteCreateManyInput | SiteCreateManyInput[]
    skipDuplicates?: boolean
  }

  /**
   * Site createManyAndReturn
   */
  export type SiteCreateManyAndReturnArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the Site
     */
    select?: SiteSelectCreateManyAndReturn<ExtArgs> | null
    /**
     * Omit specific fields from the Site
     */
    omit?: SiteOmit<ExtArgs> | null
    /**
     * The data used to create many Sites.
     */
    data: SiteCreateManyInput | SiteCreateManyInput[]
    skipDuplicates?: boolean
  }

  /**
   * Site update
   */
  export type SiteUpdateArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the Site
     */
    select?: SiteSelect<ExtArgs> | null
    /**
     * Omit specific fields from the Site
     */
    omit?: SiteOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: SiteInclude<ExtArgs> | null
    /**
     * The data needed to update a Site.
     */
    data: XOR<SiteUpdateInput, SiteUncheckedUpdateInput>
    /**
     * Choose, which Site to update.
     */
    where: SiteWhereUniqueInput
  }

  /**
   * Site updateMany
   */
  export type SiteUpdateManyArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * The data used to update Sites.
     */
    data: XOR<SiteUpdateManyMutationInput, SiteUncheckedUpdateManyInput>
    /**
     * Filter which Sites to update
     */
    where?: SiteWhereInput
    /**
     * Limit how many Sites to update.
     */
    limit?: number
  }

  /**
   * Site updateManyAndReturn
   */
  export type SiteUpdateManyAndReturnArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the Site
     */
    select?: SiteSelectUpdateManyAndReturn<ExtArgs> | null
    /**
     * Omit specific fields from the Site
     */
    omit?: SiteOmit<ExtArgs> | null
    /**
     * The data used to update Sites.
     */
    data: XOR<SiteUpdateManyMutationInput, SiteUncheckedUpdateManyInput>
    /**
     * Filter which Sites to update
     */
    where?: SiteWhereInput
    /**
     * Limit how many Sites to update.
     */
    limit?: number
  }

  /**
   * Site upsert
   */
  export type SiteUpsertArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the Site
     */
    select?: SiteSelect<ExtArgs> | null
    /**
     * Omit specific fields from the Site
     */
    omit?: SiteOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: SiteInclude<ExtArgs> | null
    /**
     * The filter to search for the Site to update in case it exists.
     */
    where: SiteWhereUniqueInput
    /**
     * In case the Site found by the `where` argument doesn't exist, create a new Site with this data.
     */
    create: XOR<SiteCreateInput, SiteUncheckedCreateInput>
    /**
     * In case the Site was found with the provided `where` argument, update it with this data.
     */
    update: XOR<SiteUpdateInput, SiteUncheckedUpdateInput>
  }

  /**
   * Site delete
   */
  export type SiteDeleteArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the Site
     */
    select?: SiteSelect<ExtArgs> | null
    /**
     * Omit specific fields from the Site
     */
    omit?: SiteOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: SiteInclude<ExtArgs> | null
    /**
     * Filter which Site to delete.
     */
    where: SiteWhereUniqueInput
  }

  /**
   * Site deleteMany
   */
  export type SiteDeleteManyArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Filter which Sites to delete
     */
    where?: SiteWhereInput
    /**
     * Limit how many Sites to delete.
     */
    limit?: number
  }

  /**
   * Site.reports
   */
  export type Site$reportsArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the Report
     */
    select?: ReportSelect<ExtArgs> | null
    /**
     * Omit specific fields from the Report
     */
    omit?: ReportOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: ReportInclude<ExtArgs> | null
    where?: ReportWhereInput
    orderBy?: ReportOrderByWithRelationInput | ReportOrderByWithRelationInput[]
    cursor?: ReportWhereUniqueInput
    take?: number
    skip?: number
    distinct?: ReportScalarFieldEnum | ReportScalarFieldEnum[]
  }

  /**
   * Site.events
   */
  export type Site$eventsArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the CleanupEvent
     */
    select?: CleanupEventSelect<ExtArgs> | null
    /**
     * Omit specific fields from the CleanupEvent
     */
    omit?: CleanupEventOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: CleanupEventInclude<ExtArgs> | null
    where?: CleanupEventWhereInput
    orderBy?: CleanupEventOrderByWithRelationInput | CleanupEventOrderByWithRelationInput[]
    cursor?: CleanupEventWhereUniqueInput
    take?: number
    skip?: number
    distinct?: CleanupEventScalarFieldEnum | CleanupEventScalarFieldEnum[]
  }

  /**
   * Site without action
   */
  export type SiteDefaultArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the Site
     */
    select?: SiteSelect<ExtArgs> | null
    /**
     * Omit specific fields from the Site
     */
    omit?: SiteOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: SiteInclude<ExtArgs> | null
  }


  /**
   * Model Report
   */

  export type AggregateReport = {
    _count: ReportCountAggregateOutputType | null
    _avg: ReportAvgAggregateOutputType | null
    _sum: ReportSumAggregateOutputType | null
    _min: ReportMinAggregateOutputType | null
    _max: ReportMaxAggregateOutputType | null
  }

  export type ReportAvgAggregateOutputType = {
    severity: number | null
  }

  export type ReportSumAggregateOutputType = {
    severity: number | null
  }

  export type ReportMinAggregateOutputType = {
    id: string | null
    createdAt: Date | null
    reportNumber: string | null
    siteId: string | null
    reporterId: string | null
    description: string | null
    category: string | null
    severity: number | null
    status: $Enums.ReportStatus | null
    moderatedAt: Date | null
    moderationReason: string | null
    moderatedById: string | null
    potentialDuplicateOfId: string | null
  }

  export type ReportMaxAggregateOutputType = {
    id: string | null
    createdAt: Date | null
    reportNumber: string | null
    siteId: string | null
    reporterId: string | null
    description: string | null
    category: string | null
    severity: number | null
    status: $Enums.ReportStatus | null
    moderatedAt: Date | null
    moderationReason: string | null
    moderatedById: string | null
    potentialDuplicateOfId: string | null
  }

  export type ReportCountAggregateOutputType = {
    id: number
    createdAt: number
    reportNumber: number
    siteId: number
    reporterId: number
    description: number
    mediaUrls: number
    category: number
    severity: number
    status: number
    moderatedAt: number
    moderationReason: number
    moderatedById: number
    potentialDuplicateOfId: number
    _all: number
  }


  export type ReportAvgAggregateInputType = {
    severity?: true
  }

  export type ReportSumAggregateInputType = {
    severity?: true
  }

  export type ReportMinAggregateInputType = {
    id?: true
    createdAt?: true
    reportNumber?: true
    siteId?: true
    reporterId?: true
    description?: true
    category?: true
    severity?: true
    status?: true
    moderatedAt?: true
    moderationReason?: true
    moderatedById?: true
    potentialDuplicateOfId?: true
  }

  export type ReportMaxAggregateInputType = {
    id?: true
    createdAt?: true
    reportNumber?: true
    siteId?: true
    reporterId?: true
    description?: true
    category?: true
    severity?: true
    status?: true
    moderatedAt?: true
    moderationReason?: true
    moderatedById?: true
    potentialDuplicateOfId?: true
  }

  export type ReportCountAggregateInputType = {
    id?: true
    createdAt?: true
    reportNumber?: true
    siteId?: true
    reporterId?: true
    description?: true
    mediaUrls?: true
    category?: true
    severity?: true
    status?: true
    moderatedAt?: true
    moderationReason?: true
    moderatedById?: true
    potentialDuplicateOfId?: true
    _all?: true
  }

  export type ReportAggregateArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Filter which Report to aggregate.
     */
    where?: ReportWhereInput
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/sorting Sorting Docs}
     * 
     * Determine the order of Reports to fetch.
     */
    orderBy?: ReportOrderByWithRelationInput | ReportOrderByWithRelationInput[]
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination#cursor-based-pagination Cursor Docs}
     * 
     * Sets the start position
     */
    cursor?: ReportWhereUniqueInput
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination Pagination Docs}
     * 
     * Take `±n` Reports from the position of the cursor.
     */
    take?: number
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination Pagination Docs}
     * 
     * Skip the first `n` Reports.
     */
    skip?: number
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/aggregations Aggregation Docs}
     * 
     * Count returned Reports
    **/
    _count?: true | ReportCountAggregateInputType
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/aggregations Aggregation Docs}
     * 
     * Select which fields to average
    **/
    _avg?: ReportAvgAggregateInputType
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/aggregations Aggregation Docs}
     * 
     * Select which fields to sum
    **/
    _sum?: ReportSumAggregateInputType
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/aggregations Aggregation Docs}
     * 
     * Select which fields to find the minimum value
    **/
    _min?: ReportMinAggregateInputType
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/aggregations Aggregation Docs}
     * 
     * Select which fields to find the maximum value
    **/
    _max?: ReportMaxAggregateInputType
  }

  export type GetReportAggregateType<T extends ReportAggregateArgs> = {
        [P in keyof T & keyof AggregateReport]: P extends '_count' | 'count'
      ? T[P] extends true
        ? number
        : GetScalarType<T[P], AggregateReport[P]>
      : GetScalarType<T[P], AggregateReport[P]>
  }




  export type ReportGroupByArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    where?: ReportWhereInput
    orderBy?: ReportOrderByWithAggregationInput | ReportOrderByWithAggregationInput[]
    by: ReportScalarFieldEnum[] | ReportScalarFieldEnum
    having?: ReportScalarWhereWithAggregatesInput
    take?: number
    skip?: number
    _count?: ReportCountAggregateInputType | true
    _avg?: ReportAvgAggregateInputType
    _sum?: ReportSumAggregateInputType
    _min?: ReportMinAggregateInputType
    _max?: ReportMaxAggregateInputType
  }

  export type ReportGroupByOutputType = {
    id: string
    createdAt: Date
    reportNumber: string | null
    siteId: string
    reporterId: string | null
    description: string | null
    mediaUrls: string[]
    category: string | null
    severity: number | null
    status: $Enums.ReportStatus
    moderatedAt: Date | null
    moderationReason: string | null
    moderatedById: string | null
    potentialDuplicateOfId: string | null
    _count: ReportCountAggregateOutputType | null
    _avg: ReportAvgAggregateOutputType | null
    _sum: ReportSumAggregateOutputType | null
    _min: ReportMinAggregateOutputType | null
    _max: ReportMaxAggregateOutputType | null
  }

  type GetReportGroupByPayload<T extends ReportGroupByArgs> = Prisma.PrismaPromise<
    Array<
      PickEnumerable<ReportGroupByOutputType, T['by']> &
        {
          [P in ((keyof T) & (keyof ReportGroupByOutputType))]: P extends '_count'
            ? T[P] extends boolean
              ? number
              : GetScalarType<T[P], ReportGroupByOutputType[P]>
            : GetScalarType<T[P], ReportGroupByOutputType[P]>
        }
      >
    >


  export type ReportSelect<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = $Extensions.GetSelect<{
    id?: boolean
    createdAt?: boolean
    reportNumber?: boolean
    siteId?: boolean
    reporterId?: boolean
    description?: boolean
    mediaUrls?: boolean
    category?: boolean
    severity?: boolean
    status?: boolean
    moderatedAt?: boolean
    moderationReason?: boolean
    moderatedById?: boolean
    potentialDuplicateOfId?: boolean
    site?: boolean | SiteDefaultArgs<ExtArgs>
    reporter?: boolean | Report$reporterArgs<ExtArgs>
    moderatedBy?: boolean | Report$moderatedByArgs<ExtArgs>
    potentialDuplicateOf?: boolean | Report$potentialDuplicateOfArgs<ExtArgs>
    potentialDuplicates?: boolean | Report$potentialDuplicatesArgs<ExtArgs>
    coReporters?: boolean | Report$coReportersArgs<ExtArgs>
    _count?: boolean | ReportCountOutputTypeDefaultArgs<ExtArgs>
  }, ExtArgs["result"]["report"]>

  export type ReportSelectCreateManyAndReturn<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = $Extensions.GetSelect<{
    id?: boolean
    createdAt?: boolean
    reportNumber?: boolean
    siteId?: boolean
    reporterId?: boolean
    description?: boolean
    mediaUrls?: boolean
    category?: boolean
    severity?: boolean
    status?: boolean
    moderatedAt?: boolean
    moderationReason?: boolean
    moderatedById?: boolean
    potentialDuplicateOfId?: boolean
    site?: boolean | SiteDefaultArgs<ExtArgs>
    reporter?: boolean | Report$reporterArgs<ExtArgs>
    moderatedBy?: boolean | Report$moderatedByArgs<ExtArgs>
    potentialDuplicateOf?: boolean | Report$potentialDuplicateOfArgs<ExtArgs>
  }, ExtArgs["result"]["report"]>

  export type ReportSelectUpdateManyAndReturn<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = $Extensions.GetSelect<{
    id?: boolean
    createdAt?: boolean
    reportNumber?: boolean
    siteId?: boolean
    reporterId?: boolean
    description?: boolean
    mediaUrls?: boolean
    category?: boolean
    severity?: boolean
    status?: boolean
    moderatedAt?: boolean
    moderationReason?: boolean
    moderatedById?: boolean
    potentialDuplicateOfId?: boolean
    site?: boolean | SiteDefaultArgs<ExtArgs>
    reporter?: boolean | Report$reporterArgs<ExtArgs>
    moderatedBy?: boolean | Report$moderatedByArgs<ExtArgs>
    potentialDuplicateOf?: boolean | Report$potentialDuplicateOfArgs<ExtArgs>
  }, ExtArgs["result"]["report"]>

  export type ReportSelectScalar = {
    id?: boolean
    createdAt?: boolean
    reportNumber?: boolean
    siteId?: boolean
    reporterId?: boolean
    description?: boolean
    mediaUrls?: boolean
    category?: boolean
    severity?: boolean
    status?: boolean
    moderatedAt?: boolean
    moderationReason?: boolean
    moderatedById?: boolean
    potentialDuplicateOfId?: boolean
  }

  export type ReportOmit<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = $Extensions.GetOmit<"id" | "createdAt" | "reportNumber" | "siteId" | "reporterId" | "description" | "mediaUrls" | "category" | "severity" | "status" | "moderatedAt" | "moderationReason" | "moderatedById" | "potentialDuplicateOfId", ExtArgs["result"]["report"]>
  export type ReportInclude<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    site?: boolean | SiteDefaultArgs<ExtArgs>
    reporter?: boolean | Report$reporterArgs<ExtArgs>
    moderatedBy?: boolean | Report$moderatedByArgs<ExtArgs>
    potentialDuplicateOf?: boolean | Report$potentialDuplicateOfArgs<ExtArgs>
    potentialDuplicates?: boolean | Report$potentialDuplicatesArgs<ExtArgs>
    coReporters?: boolean | Report$coReportersArgs<ExtArgs>
    _count?: boolean | ReportCountOutputTypeDefaultArgs<ExtArgs>
  }
  export type ReportIncludeCreateManyAndReturn<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    site?: boolean | SiteDefaultArgs<ExtArgs>
    reporter?: boolean | Report$reporterArgs<ExtArgs>
    moderatedBy?: boolean | Report$moderatedByArgs<ExtArgs>
    potentialDuplicateOf?: boolean | Report$potentialDuplicateOfArgs<ExtArgs>
  }
  export type ReportIncludeUpdateManyAndReturn<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    site?: boolean | SiteDefaultArgs<ExtArgs>
    reporter?: boolean | Report$reporterArgs<ExtArgs>
    moderatedBy?: boolean | Report$moderatedByArgs<ExtArgs>
    potentialDuplicateOf?: boolean | Report$potentialDuplicateOfArgs<ExtArgs>
  }

  export type $ReportPayload<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    name: "Report"
    objects: {
      site: Prisma.$SitePayload<ExtArgs>
      reporter: Prisma.$UserPayload<ExtArgs> | null
      moderatedBy: Prisma.$UserPayload<ExtArgs> | null
      potentialDuplicateOf: Prisma.$ReportPayload<ExtArgs> | null
      potentialDuplicates: Prisma.$ReportPayload<ExtArgs>[]
      coReporters: Prisma.$ReportCoReporterPayload<ExtArgs>[]
    }
    scalars: $Extensions.GetPayloadResult<{
      id: string
      createdAt: Date
      reportNumber: string | null
      siteId: string
      reporterId: string | null
      description: string | null
      mediaUrls: string[]
      category: string | null
      severity: number | null
      status: $Enums.ReportStatus
      moderatedAt: Date | null
      moderationReason: string | null
      moderatedById: string | null
      potentialDuplicateOfId: string | null
    }, ExtArgs["result"]["report"]>
    composites: {}
  }

  type ReportGetPayload<S extends boolean | null | undefined | ReportDefaultArgs> = $Result.GetResult<Prisma.$ReportPayload, S>

  type ReportCountArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> =
    Omit<ReportFindManyArgs, 'select' | 'include' | 'distinct' | 'omit'> & {
      select?: ReportCountAggregateInputType | true
    }

  export interface ReportDelegate<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs, GlobalOmitOptions = {}> {
    [K: symbol]: { types: Prisma.TypeMap<ExtArgs>['model']['Report'], meta: { name: 'Report' } }
    /**
     * Find zero or one Report that matches the filter.
     * @param {ReportFindUniqueArgs} args - Arguments to find a Report
     * @example
     * // Get one Report
     * const report = await prisma.report.findUnique({
     *   where: {
     *     // ... provide filter here
     *   }
     * })
     */
    findUnique<T extends ReportFindUniqueArgs>(args: SelectSubset<T, ReportFindUniqueArgs<ExtArgs>>): Prisma__ReportClient<$Result.GetResult<Prisma.$ReportPayload<ExtArgs>, T, "findUnique", GlobalOmitOptions> | null, null, ExtArgs, GlobalOmitOptions>

    /**
     * Find one Report that matches the filter or throw an error with `error.code='P2025'`
     * if no matches were found.
     * @param {ReportFindUniqueOrThrowArgs} args - Arguments to find a Report
     * @example
     * // Get one Report
     * const report = await prisma.report.findUniqueOrThrow({
     *   where: {
     *     // ... provide filter here
     *   }
     * })
     */
    findUniqueOrThrow<T extends ReportFindUniqueOrThrowArgs>(args: SelectSubset<T, ReportFindUniqueOrThrowArgs<ExtArgs>>): Prisma__ReportClient<$Result.GetResult<Prisma.$ReportPayload<ExtArgs>, T, "findUniqueOrThrow", GlobalOmitOptions>, never, ExtArgs, GlobalOmitOptions>

    /**
     * Find the first Report that matches the filter.
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * @param {ReportFindFirstArgs} args - Arguments to find a Report
     * @example
     * // Get one Report
     * const report = await prisma.report.findFirst({
     *   where: {
     *     // ... provide filter here
     *   }
     * })
     */
    findFirst<T extends ReportFindFirstArgs>(args?: SelectSubset<T, ReportFindFirstArgs<ExtArgs>>): Prisma__ReportClient<$Result.GetResult<Prisma.$ReportPayload<ExtArgs>, T, "findFirst", GlobalOmitOptions> | null, null, ExtArgs, GlobalOmitOptions>

    /**
     * Find the first Report that matches the filter or
     * throw `PrismaKnownClientError` with `P2025` code if no matches were found.
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * @param {ReportFindFirstOrThrowArgs} args - Arguments to find a Report
     * @example
     * // Get one Report
     * const report = await prisma.report.findFirstOrThrow({
     *   where: {
     *     // ... provide filter here
     *   }
     * })
     */
    findFirstOrThrow<T extends ReportFindFirstOrThrowArgs>(args?: SelectSubset<T, ReportFindFirstOrThrowArgs<ExtArgs>>): Prisma__ReportClient<$Result.GetResult<Prisma.$ReportPayload<ExtArgs>, T, "findFirstOrThrow", GlobalOmitOptions>, never, ExtArgs, GlobalOmitOptions>

    /**
     * Find zero or more Reports that matches the filter.
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * @param {ReportFindManyArgs} args - Arguments to filter and select certain fields only.
     * @example
     * // Get all Reports
     * const reports = await prisma.report.findMany()
     * 
     * // Get first 10 Reports
     * const reports = await prisma.report.findMany({ take: 10 })
     * 
     * // Only select the `id`
     * const reportWithIdOnly = await prisma.report.findMany({ select: { id: true } })
     * 
     */
    findMany<T extends ReportFindManyArgs>(args?: SelectSubset<T, ReportFindManyArgs<ExtArgs>>): Prisma.PrismaPromise<$Result.GetResult<Prisma.$ReportPayload<ExtArgs>, T, "findMany", GlobalOmitOptions>>

    /**
     * Create a Report.
     * @param {ReportCreateArgs} args - Arguments to create a Report.
     * @example
     * // Create one Report
     * const Report = await prisma.report.create({
     *   data: {
     *     // ... data to create a Report
     *   }
     * })
     * 
     */
    create<T extends ReportCreateArgs>(args: SelectSubset<T, ReportCreateArgs<ExtArgs>>): Prisma__ReportClient<$Result.GetResult<Prisma.$ReportPayload<ExtArgs>, T, "create", GlobalOmitOptions>, never, ExtArgs, GlobalOmitOptions>

    /**
     * Create many Reports.
     * @param {ReportCreateManyArgs} args - Arguments to create many Reports.
     * @example
     * // Create many Reports
     * const report = await prisma.report.createMany({
     *   data: [
     *     // ... provide data here
     *   ]
     * })
     *     
     */
    createMany<T extends ReportCreateManyArgs>(args?: SelectSubset<T, ReportCreateManyArgs<ExtArgs>>): Prisma.PrismaPromise<BatchPayload>

    /**
     * Create many Reports and returns the data saved in the database.
     * @param {ReportCreateManyAndReturnArgs} args - Arguments to create many Reports.
     * @example
     * // Create many Reports
     * const report = await prisma.report.createManyAndReturn({
     *   data: [
     *     // ... provide data here
     *   ]
     * })
     * 
     * // Create many Reports and only return the `id`
     * const reportWithIdOnly = await prisma.report.createManyAndReturn({
     *   select: { id: true },
     *   data: [
     *     // ... provide data here
     *   ]
     * })
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * 
     */
    createManyAndReturn<T extends ReportCreateManyAndReturnArgs>(args?: SelectSubset<T, ReportCreateManyAndReturnArgs<ExtArgs>>): Prisma.PrismaPromise<$Result.GetResult<Prisma.$ReportPayload<ExtArgs>, T, "createManyAndReturn", GlobalOmitOptions>>

    /**
     * Delete a Report.
     * @param {ReportDeleteArgs} args - Arguments to delete one Report.
     * @example
     * // Delete one Report
     * const Report = await prisma.report.delete({
     *   where: {
     *     // ... filter to delete one Report
     *   }
     * })
     * 
     */
    delete<T extends ReportDeleteArgs>(args: SelectSubset<T, ReportDeleteArgs<ExtArgs>>): Prisma__ReportClient<$Result.GetResult<Prisma.$ReportPayload<ExtArgs>, T, "delete", GlobalOmitOptions>, never, ExtArgs, GlobalOmitOptions>

    /**
     * Update one Report.
     * @param {ReportUpdateArgs} args - Arguments to update one Report.
     * @example
     * // Update one Report
     * const report = await prisma.report.update({
     *   where: {
     *     // ... provide filter here
     *   },
     *   data: {
     *     // ... provide data here
     *   }
     * })
     * 
     */
    update<T extends ReportUpdateArgs>(args: SelectSubset<T, ReportUpdateArgs<ExtArgs>>): Prisma__ReportClient<$Result.GetResult<Prisma.$ReportPayload<ExtArgs>, T, "update", GlobalOmitOptions>, never, ExtArgs, GlobalOmitOptions>

    /**
     * Delete zero or more Reports.
     * @param {ReportDeleteManyArgs} args - Arguments to filter Reports to delete.
     * @example
     * // Delete a few Reports
     * const { count } = await prisma.report.deleteMany({
     *   where: {
     *     // ... provide filter here
     *   }
     * })
     * 
     */
    deleteMany<T extends ReportDeleteManyArgs>(args?: SelectSubset<T, ReportDeleteManyArgs<ExtArgs>>): Prisma.PrismaPromise<BatchPayload>

    /**
     * Update zero or more Reports.
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * @param {ReportUpdateManyArgs} args - Arguments to update one or more rows.
     * @example
     * // Update many Reports
     * const report = await prisma.report.updateMany({
     *   where: {
     *     // ... provide filter here
     *   },
     *   data: {
     *     // ... provide data here
     *   }
     * })
     * 
     */
    updateMany<T extends ReportUpdateManyArgs>(args: SelectSubset<T, ReportUpdateManyArgs<ExtArgs>>): Prisma.PrismaPromise<BatchPayload>

    /**
     * Update zero or more Reports and returns the data updated in the database.
     * @param {ReportUpdateManyAndReturnArgs} args - Arguments to update many Reports.
     * @example
     * // Update many Reports
     * const report = await prisma.report.updateManyAndReturn({
     *   where: {
     *     // ... provide filter here
     *   },
     *   data: [
     *     // ... provide data here
     *   ]
     * })
     * 
     * // Update zero or more Reports and only return the `id`
     * const reportWithIdOnly = await prisma.report.updateManyAndReturn({
     *   select: { id: true },
     *   where: {
     *     // ... provide filter here
     *   },
     *   data: [
     *     // ... provide data here
     *   ]
     * })
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * 
     */
    updateManyAndReturn<T extends ReportUpdateManyAndReturnArgs>(args: SelectSubset<T, ReportUpdateManyAndReturnArgs<ExtArgs>>): Prisma.PrismaPromise<$Result.GetResult<Prisma.$ReportPayload<ExtArgs>, T, "updateManyAndReturn", GlobalOmitOptions>>

    /**
     * Create or update one Report.
     * @param {ReportUpsertArgs} args - Arguments to update or create a Report.
     * @example
     * // Update or create a Report
     * const report = await prisma.report.upsert({
     *   create: {
     *     // ... data to create a Report
     *   },
     *   update: {
     *     // ... in case it already exists, update
     *   },
     *   where: {
     *     // ... the filter for the Report we want to update
     *   }
     * })
     */
    upsert<T extends ReportUpsertArgs>(args: SelectSubset<T, ReportUpsertArgs<ExtArgs>>): Prisma__ReportClient<$Result.GetResult<Prisma.$ReportPayload<ExtArgs>, T, "upsert", GlobalOmitOptions>, never, ExtArgs, GlobalOmitOptions>


    /**
     * Count the number of Reports.
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * @param {ReportCountArgs} args - Arguments to filter Reports to count.
     * @example
     * // Count the number of Reports
     * const count = await prisma.report.count({
     *   where: {
     *     // ... the filter for the Reports we want to count
     *   }
     * })
    **/
    count<T extends ReportCountArgs>(
      args?: Subset<T, ReportCountArgs>,
    ): Prisma.PrismaPromise<
      T extends $Utils.Record<'select', any>
        ? T['select'] extends true
          ? number
          : GetScalarType<T['select'], ReportCountAggregateOutputType>
        : number
    >

    /**
     * Allows you to perform aggregations operations on a Report.
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * @param {ReportAggregateArgs} args - Select which aggregations you would like to apply and on what fields.
     * @example
     * // Ordered by age ascending
     * // Where email contains prisma.io
     * // Limited to the 10 users
     * const aggregations = await prisma.user.aggregate({
     *   _avg: {
     *     age: true,
     *   },
     *   where: {
     *     email: {
     *       contains: "prisma.io",
     *     },
     *   },
     *   orderBy: {
     *     age: "asc",
     *   },
     *   take: 10,
     * })
    **/
    aggregate<T extends ReportAggregateArgs>(args: Subset<T, ReportAggregateArgs>): Prisma.PrismaPromise<GetReportAggregateType<T>>

    /**
     * Group by Report.
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * @param {ReportGroupByArgs} args - Group by arguments.
     * @example
     * // Group by city, order by createdAt, get count
     * const result = await prisma.user.groupBy({
     *   by: ['city', 'createdAt'],
     *   orderBy: {
     *     createdAt: true
     *   },
     *   _count: {
     *     _all: true
     *   },
     * })
     * 
    **/
    groupBy<
      T extends ReportGroupByArgs,
      HasSelectOrTake extends Or<
        Extends<'skip', Keys<T>>,
        Extends<'take', Keys<T>>
      >,
      OrderByArg extends True extends HasSelectOrTake
        ? { orderBy: ReportGroupByArgs['orderBy'] }
        : { orderBy?: ReportGroupByArgs['orderBy'] },
      OrderFields extends ExcludeUnderscoreKeys<Keys<MaybeTupleToUnion<T['orderBy']>>>,
      ByFields extends MaybeTupleToUnion<T['by']>,
      ByValid extends Has<ByFields, OrderFields>,
      HavingFields extends GetHavingFields<T['having']>,
      HavingValid extends Has<ByFields, HavingFields>,
      ByEmpty extends T['by'] extends never[] ? True : False,
      InputErrors extends ByEmpty extends True
      ? `Error: "by" must not be empty.`
      : HavingValid extends False
      ? {
          [P in HavingFields]: P extends ByFields
            ? never
            : P extends string
            ? `Error: Field "${P}" used in "having" needs to be provided in "by".`
            : [
                Error,
                'Field ',
                P,
                ` in "having" needs to be provided in "by"`,
              ]
        }[HavingFields]
      : 'take' extends Keys<T>
      ? 'orderBy' extends Keys<T>
        ? ByValid extends True
          ? {}
          : {
              [P in OrderFields]: P extends ByFields
                ? never
                : `Error: Field "${P}" in "orderBy" needs to be provided in "by"`
            }[OrderFields]
        : 'Error: If you provide "take", you also need to provide "orderBy"'
      : 'skip' extends Keys<T>
      ? 'orderBy' extends Keys<T>
        ? ByValid extends True
          ? {}
          : {
              [P in OrderFields]: P extends ByFields
                ? never
                : `Error: Field "${P}" in "orderBy" needs to be provided in "by"`
            }[OrderFields]
        : 'Error: If you provide "skip", you also need to provide "orderBy"'
      : ByValid extends True
      ? {}
      : {
          [P in OrderFields]: P extends ByFields
            ? never
            : `Error: Field "${P}" in "orderBy" needs to be provided in "by"`
        }[OrderFields]
    >(args: SubsetIntersection<T, ReportGroupByArgs, OrderByArg> & InputErrors): {} extends InputErrors ? GetReportGroupByPayload<T> : Prisma.PrismaPromise<InputErrors>
  /**
   * Fields of the Report model
   */
  readonly fields: ReportFieldRefs;
  }

  /**
   * The delegate class that acts as a "Promise-like" for Report.
   * Why is this prefixed with `Prisma__`?
   * Because we want to prevent naming conflicts as mentioned in
   * https://github.com/prisma/prisma-client-js/issues/707
   */
  export interface Prisma__ReportClient<T, Null = never, ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs, GlobalOmitOptions = {}> extends Prisma.PrismaPromise<T> {
    readonly [Symbol.toStringTag]: "PrismaPromise"
    site<T extends SiteDefaultArgs<ExtArgs> = {}>(args?: Subset<T, SiteDefaultArgs<ExtArgs>>): Prisma__SiteClient<$Result.GetResult<Prisma.$SitePayload<ExtArgs>, T, "findUniqueOrThrow", GlobalOmitOptions> | Null, Null, ExtArgs, GlobalOmitOptions>
    reporter<T extends Report$reporterArgs<ExtArgs> = {}>(args?: Subset<T, Report$reporterArgs<ExtArgs>>): Prisma__UserClient<$Result.GetResult<Prisma.$UserPayload<ExtArgs>, T, "findUniqueOrThrow", GlobalOmitOptions> | null, null, ExtArgs, GlobalOmitOptions>
    moderatedBy<T extends Report$moderatedByArgs<ExtArgs> = {}>(args?: Subset<T, Report$moderatedByArgs<ExtArgs>>): Prisma__UserClient<$Result.GetResult<Prisma.$UserPayload<ExtArgs>, T, "findUniqueOrThrow", GlobalOmitOptions> | null, null, ExtArgs, GlobalOmitOptions>
    potentialDuplicateOf<T extends Report$potentialDuplicateOfArgs<ExtArgs> = {}>(args?: Subset<T, Report$potentialDuplicateOfArgs<ExtArgs>>): Prisma__ReportClient<$Result.GetResult<Prisma.$ReportPayload<ExtArgs>, T, "findUniqueOrThrow", GlobalOmitOptions> | null, null, ExtArgs, GlobalOmitOptions>
    potentialDuplicates<T extends Report$potentialDuplicatesArgs<ExtArgs> = {}>(args?: Subset<T, Report$potentialDuplicatesArgs<ExtArgs>>): Prisma.PrismaPromise<$Result.GetResult<Prisma.$ReportPayload<ExtArgs>, T, "findMany", GlobalOmitOptions> | Null>
    coReporters<T extends Report$coReportersArgs<ExtArgs> = {}>(args?: Subset<T, Report$coReportersArgs<ExtArgs>>): Prisma.PrismaPromise<$Result.GetResult<Prisma.$ReportCoReporterPayload<ExtArgs>, T, "findMany", GlobalOmitOptions> | Null>
    /**
     * Attaches callbacks for the resolution and/or rejection of the Promise.
     * @param onfulfilled The callback to execute when the Promise is resolved.
     * @param onrejected The callback to execute when the Promise is rejected.
     * @returns A Promise for the completion of which ever callback is executed.
     */
    then<TResult1 = T, TResult2 = never>(onfulfilled?: ((value: T) => TResult1 | PromiseLike<TResult1>) | undefined | null, onrejected?: ((reason: any) => TResult2 | PromiseLike<TResult2>) | undefined | null): $Utils.JsPromise<TResult1 | TResult2>
    /**
     * Attaches a callback for only the rejection of the Promise.
     * @param onrejected The callback to execute when the Promise is rejected.
     * @returns A Promise for the completion of the callback.
     */
    catch<TResult = never>(onrejected?: ((reason: any) => TResult | PromiseLike<TResult>) | undefined | null): $Utils.JsPromise<T | TResult>
    /**
     * Attaches a callback that is invoked when the Promise is settled (fulfilled or rejected). The
     * resolved value cannot be modified from the callback.
     * @param onfinally The callback to execute when the Promise is settled (fulfilled or rejected).
     * @returns A Promise for the completion of the callback.
     */
    finally(onfinally?: (() => void) | undefined | null): $Utils.JsPromise<T>
  }




  /**
   * Fields of the Report model
   */
  interface ReportFieldRefs {
    readonly id: FieldRef<"Report", 'String'>
    readonly createdAt: FieldRef<"Report", 'DateTime'>
    readonly reportNumber: FieldRef<"Report", 'String'>
    readonly siteId: FieldRef<"Report", 'String'>
    readonly reporterId: FieldRef<"Report", 'String'>
    readonly description: FieldRef<"Report", 'String'>
    readonly mediaUrls: FieldRef<"Report", 'String[]'>
    readonly category: FieldRef<"Report", 'String'>
    readonly severity: FieldRef<"Report", 'Int'>
    readonly status: FieldRef<"Report", 'ReportStatus'>
    readonly moderatedAt: FieldRef<"Report", 'DateTime'>
    readonly moderationReason: FieldRef<"Report", 'String'>
    readonly moderatedById: FieldRef<"Report", 'String'>
    readonly potentialDuplicateOfId: FieldRef<"Report", 'String'>
  }
    

  // Custom InputTypes
  /**
   * Report findUnique
   */
  export type ReportFindUniqueArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the Report
     */
    select?: ReportSelect<ExtArgs> | null
    /**
     * Omit specific fields from the Report
     */
    omit?: ReportOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: ReportInclude<ExtArgs> | null
    /**
     * Filter, which Report to fetch.
     */
    where: ReportWhereUniqueInput
  }

  /**
   * Report findUniqueOrThrow
   */
  export type ReportFindUniqueOrThrowArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the Report
     */
    select?: ReportSelect<ExtArgs> | null
    /**
     * Omit specific fields from the Report
     */
    omit?: ReportOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: ReportInclude<ExtArgs> | null
    /**
     * Filter, which Report to fetch.
     */
    where: ReportWhereUniqueInput
  }

  /**
   * Report findFirst
   */
  export type ReportFindFirstArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the Report
     */
    select?: ReportSelect<ExtArgs> | null
    /**
     * Omit specific fields from the Report
     */
    omit?: ReportOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: ReportInclude<ExtArgs> | null
    /**
     * Filter, which Report to fetch.
     */
    where?: ReportWhereInput
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/sorting Sorting Docs}
     * 
     * Determine the order of Reports to fetch.
     */
    orderBy?: ReportOrderByWithRelationInput | ReportOrderByWithRelationInput[]
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination#cursor-based-pagination Cursor Docs}
     * 
     * Sets the position for searching for Reports.
     */
    cursor?: ReportWhereUniqueInput
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination Pagination Docs}
     * 
     * Take `±n` Reports from the position of the cursor.
     */
    take?: number
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination Pagination Docs}
     * 
     * Skip the first `n` Reports.
     */
    skip?: number
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/distinct Distinct Docs}
     * 
     * Filter by unique combinations of Reports.
     */
    distinct?: ReportScalarFieldEnum | ReportScalarFieldEnum[]
  }

  /**
   * Report findFirstOrThrow
   */
  export type ReportFindFirstOrThrowArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the Report
     */
    select?: ReportSelect<ExtArgs> | null
    /**
     * Omit specific fields from the Report
     */
    omit?: ReportOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: ReportInclude<ExtArgs> | null
    /**
     * Filter, which Report to fetch.
     */
    where?: ReportWhereInput
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/sorting Sorting Docs}
     * 
     * Determine the order of Reports to fetch.
     */
    orderBy?: ReportOrderByWithRelationInput | ReportOrderByWithRelationInput[]
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination#cursor-based-pagination Cursor Docs}
     * 
     * Sets the position for searching for Reports.
     */
    cursor?: ReportWhereUniqueInput
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination Pagination Docs}
     * 
     * Take `±n` Reports from the position of the cursor.
     */
    take?: number
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination Pagination Docs}
     * 
     * Skip the first `n` Reports.
     */
    skip?: number
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/distinct Distinct Docs}
     * 
     * Filter by unique combinations of Reports.
     */
    distinct?: ReportScalarFieldEnum | ReportScalarFieldEnum[]
  }

  /**
   * Report findMany
   */
  export type ReportFindManyArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the Report
     */
    select?: ReportSelect<ExtArgs> | null
    /**
     * Omit specific fields from the Report
     */
    omit?: ReportOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: ReportInclude<ExtArgs> | null
    /**
     * Filter, which Reports to fetch.
     */
    where?: ReportWhereInput
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/sorting Sorting Docs}
     * 
     * Determine the order of Reports to fetch.
     */
    orderBy?: ReportOrderByWithRelationInput | ReportOrderByWithRelationInput[]
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination#cursor-based-pagination Cursor Docs}
     * 
     * Sets the position for listing Reports.
     */
    cursor?: ReportWhereUniqueInput
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination Pagination Docs}
     * 
     * Take `±n` Reports from the position of the cursor.
     */
    take?: number
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination Pagination Docs}
     * 
     * Skip the first `n` Reports.
     */
    skip?: number
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/distinct Distinct Docs}
     * 
     * Filter by unique combinations of Reports.
     */
    distinct?: ReportScalarFieldEnum | ReportScalarFieldEnum[]
  }

  /**
   * Report create
   */
  export type ReportCreateArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the Report
     */
    select?: ReportSelect<ExtArgs> | null
    /**
     * Omit specific fields from the Report
     */
    omit?: ReportOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: ReportInclude<ExtArgs> | null
    /**
     * The data needed to create a Report.
     */
    data: XOR<ReportCreateInput, ReportUncheckedCreateInput>
  }

  /**
   * Report createMany
   */
  export type ReportCreateManyArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * The data used to create many Reports.
     */
    data: ReportCreateManyInput | ReportCreateManyInput[]
    skipDuplicates?: boolean
  }

  /**
   * Report createManyAndReturn
   */
  export type ReportCreateManyAndReturnArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the Report
     */
    select?: ReportSelectCreateManyAndReturn<ExtArgs> | null
    /**
     * Omit specific fields from the Report
     */
    omit?: ReportOmit<ExtArgs> | null
    /**
     * The data used to create many Reports.
     */
    data: ReportCreateManyInput | ReportCreateManyInput[]
    skipDuplicates?: boolean
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: ReportIncludeCreateManyAndReturn<ExtArgs> | null
  }

  /**
   * Report update
   */
  export type ReportUpdateArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the Report
     */
    select?: ReportSelect<ExtArgs> | null
    /**
     * Omit specific fields from the Report
     */
    omit?: ReportOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: ReportInclude<ExtArgs> | null
    /**
     * The data needed to update a Report.
     */
    data: XOR<ReportUpdateInput, ReportUncheckedUpdateInput>
    /**
     * Choose, which Report to update.
     */
    where: ReportWhereUniqueInput
  }

  /**
   * Report updateMany
   */
  export type ReportUpdateManyArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * The data used to update Reports.
     */
    data: XOR<ReportUpdateManyMutationInput, ReportUncheckedUpdateManyInput>
    /**
     * Filter which Reports to update
     */
    where?: ReportWhereInput
    /**
     * Limit how many Reports to update.
     */
    limit?: number
  }

  /**
   * Report updateManyAndReturn
   */
  export type ReportUpdateManyAndReturnArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the Report
     */
    select?: ReportSelectUpdateManyAndReturn<ExtArgs> | null
    /**
     * Omit specific fields from the Report
     */
    omit?: ReportOmit<ExtArgs> | null
    /**
     * The data used to update Reports.
     */
    data: XOR<ReportUpdateManyMutationInput, ReportUncheckedUpdateManyInput>
    /**
     * Filter which Reports to update
     */
    where?: ReportWhereInput
    /**
     * Limit how many Reports to update.
     */
    limit?: number
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: ReportIncludeUpdateManyAndReturn<ExtArgs> | null
  }

  /**
   * Report upsert
   */
  export type ReportUpsertArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the Report
     */
    select?: ReportSelect<ExtArgs> | null
    /**
     * Omit specific fields from the Report
     */
    omit?: ReportOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: ReportInclude<ExtArgs> | null
    /**
     * The filter to search for the Report to update in case it exists.
     */
    where: ReportWhereUniqueInput
    /**
     * In case the Report found by the `where` argument doesn't exist, create a new Report with this data.
     */
    create: XOR<ReportCreateInput, ReportUncheckedCreateInput>
    /**
     * In case the Report was found with the provided `where` argument, update it with this data.
     */
    update: XOR<ReportUpdateInput, ReportUncheckedUpdateInput>
  }

  /**
   * Report delete
   */
  export type ReportDeleteArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the Report
     */
    select?: ReportSelect<ExtArgs> | null
    /**
     * Omit specific fields from the Report
     */
    omit?: ReportOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: ReportInclude<ExtArgs> | null
    /**
     * Filter which Report to delete.
     */
    where: ReportWhereUniqueInput
  }

  /**
   * Report deleteMany
   */
  export type ReportDeleteManyArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Filter which Reports to delete
     */
    where?: ReportWhereInput
    /**
     * Limit how many Reports to delete.
     */
    limit?: number
  }

  /**
   * Report.reporter
   */
  export type Report$reporterArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the User
     */
    select?: UserSelect<ExtArgs> | null
    /**
     * Omit specific fields from the User
     */
    omit?: UserOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: UserInclude<ExtArgs> | null
    where?: UserWhereInput
  }

  /**
   * Report.moderatedBy
   */
  export type Report$moderatedByArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the User
     */
    select?: UserSelect<ExtArgs> | null
    /**
     * Omit specific fields from the User
     */
    omit?: UserOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: UserInclude<ExtArgs> | null
    where?: UserWhereInput
  }

  /**
   * Report.potentialDuplicateOf
   */
  export type Report$potentialDuplicateOfArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the Report
     */
    select?: ReportSelect<ExtArgs> | null
    /**
     * Omit specific fields from the Report
     */
    omit?: ReportOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: ReportInclude<ExtArgs> | null
    where?: ReportWhereInput
  }

  /**
   * Report.potentialDuplicates
   */
  export type Report$potentialDuplicatesArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the Report
     */
    select?: ReportSelect<ExtArgs> | null
    /**
     * Omit specific fields from the Report
     */
    omit?: ReportOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: ReportInclude<ExtArgs> | null
    where?: ReportWhereInput
    orderBy?: ReportOrderByWithRelationInput | ReportOrderByWithRelationInput[]
    cursor?: ReportWhereUniqueInput
    take?: number
    skip?: number
    distinct?: ReportScalarFieldEnum | ReportScalarFieldEnum[]
  }

  /**
   * Report.coReporters
   */
  export type Report$coReportersArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the ReportCoReporter
     */
    select?: ReportCoReporterSelect<ExtArgs> | null
    /**
     * Omit specific fields from the ReportCoReporter
     */
    omit?: ReportCoReporterOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: ReportCoReporterInclude<ExtArgs> | null
    where?: ReportCoReporterWhereInput
    orderBy?: ReportCoReporterOrderByWithRelationInput | ReportCoReporterOrderByWithRelationInput[]
    cursor?: ReportCoReporterWhereUniqueInput
    take?: number
    skip?: number
    distinct?: ReportCoReporterScalarFieldEnum | ReportCoReporterScalarFieldEnum[]
  }

  /**
   * Report without action
   */
  export type ReportDefaultArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the Report
     */
    select?: ReportSelect<ExtArgs> | null
    /**
     * Omit specific fields from the Report
     */
    omit?: ReportOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: ReportInclude<ExtArgs> | null
  }


  /**
   * Model ReportCoReporter
   */

  export type AggregateReportCoReporter = {
    _count: ReportCoReporterCountAggregateOutputType | null
    _min: ReportCoReporterMinAggregateOutputType | null
    _max: ReportCoReporterMaxAggregateOutputType | null
  }

  export type ReportCoReporterMinAggregateOutputType = {
    id: string | null
    createdAt: Date | null
    reportId: string | null
    userId: string | null
  }

  export type ReportCoReporterMaxAggregateOutputType = {
    id: string | null
    createdAt: Date | null
    reportId: string | null
    userId: string | null
  }

  export type ReportCoReporterCountAggregateOutputType = {
    id: number
    createdAt: number
    reportId: number
    userId: number
    _all: number
  }


  export type ReportCoReporterMinAggregateInputType = {
    id?: true
    createdAt?: true
    reportId?: true
    userId?: true
  }

  export type ReportCoReporterMaxAggregateInputType = {
    id?: true
    createdAt?: true
    reportId?: true
    userId?: true
  }

  export type ReportCoReporterCountAggregateInputType = {
    id?: true
    createdAt?: true
    reportId?: true
    userId?: true
    _all?: true
  }

  export type ReportCoReporterAggregateArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Filter which ReportCoReporter to aggregate.
     */
    where?: ReportCoReporterWhereInput
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/sorting Sorting Docs}
     * 
     * Determine the order of ReportCoReporters to fetch.
     */
    orderBy?: ReportCoReporterOrderByWithRelationInput | ReportCoReporterOrderByWithRelationInput[]
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination#cursor-based-pagination Cursor Docs}
     * 
     * Sets the start position
     */
    cursor?: ReportCoReporterWhereUniqueInput
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination Pagination Docs}
     * 
     * Take `±n` ReportCoReporters from the position of the cursor.
     */
    take?: number
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination Pagination Docs}
     * 
     * Skip the first `n` ReportCoReporters.
     */
    skip?: number
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/aggregations Aggregation Docs}
     * 
     * Count returned ReportCoReporters
    **/
    _count?: true | ReportCoReporterCountAggregateInputType
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/aggregations Aggregation Docs}
     * 
     * Select which fields to find the minimum value
    **/
    _min?: ReportCoReporterMinAggregateInputType
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/aggregations Aggregation Docs}
     * 
     * Select which fields to find the maximum value
    **/
    _max?: ReportCoReporterMaxAggregateInputType
  }

  export type GetReportCoReporterAggregateType<T extends ReportCoReporterAggregateArgs> = {
        [P in keyof T & keyof AggregateReportCoReporter]: P extends '_count' | 'count'
      ? T[P] extends true
        ? number
        : GetScalarType<T[P], AggregateReportCoReporter[P]>
      : GetScalarType<T[P], AggregateReportCoReporter[P]>
  }




  export type ReportCoReporterGroupByArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    where?: ReportCoReporterWhereInput
    orderBy?: ReportCoReporterOrderByWithAggregationInput | ReportCoReporterOrderByWithAggregationInput[]
    by: ReportCoReporterScalarFieldEnum[] | ReportCoReporterScalarFieldEnum
    having?: ReportCoReporterScalarWhereWithAggregatesInput
    take?: number
    skip?: number
    _count?: ReportCoReporterCountAggregateInputType | true
    _min?: ReportCoReporterMinAggregateInputType
    _max?: ReportCoReporterMaxAggregateInputType
  }

  export type ReportCoReporterGroupByOutputType = {
    id: string
    createdAt: Date
    reportId: string
    userId: string
    _count: ReportCoReporterCountAggregateOutputType | null
    _min: ReportCoReporterMinAggregateOutputType | null
    _max: ReportCoReporterMaxAggregateOutputType | null
  }

  type GetReportCoReporterGroupByPayload<T extends ReportCoReporterGroupByArgs> = Prisma.PrismaPromise<
    Array<
      PickEnumerable<ReportCoReporterGroupByOutputType, T['by']> &
        {
          [P in ((keyof T) & (keyof ReportCoReporterGroupByOutputType))]: P extends '_count'
            ? T[P] extends boolean
              ? number
              : GetScalarType<T[P], ReportCoReporterGroupByOutputType[P]>
            : GetScalarType<T[P], ReportCoReporterGroupByOutputType[P]>
        }
      >
    >


  export type ReportCoReporterSelect<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = $Extensions.GetSelect<{
    id?: boolean
    createdAt?: boolean
    reportId?: boolean
    userId?: boolean
    report?: boolean | ReportDefaultArgs<ExtArgs>
    user?: boolean | UserDefaultArgs<ExtArgs>
  }, ExtArgs["result"]["reportCoReporter"]>

  export type ReportCoReporterSelectCreateManyAndReturn<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = $Extensions.GetSelect<{
    id?: boolean
    createdAt?: boolean
    reportId?: boolean
    userId?: boolean
    report?: boolean | ReportDefaultArgs<ExtArgs>
    user?: boolean | UserDefaultArgs<ExtArgs>
  }, ExtArgs["result"]["reportCoReporter"]>

  export type ReportCoReporterSelectUpdateManyAndReturn<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = $Extensions.GetSelect<{
    id?: boolean
    createdAt?: boolean
    reportId?: boolean
    userId?: boolean
    report?: boolean | ReportDefaultArgs<ExtArgs>
    user?: boolean | UserDefaultArgs<ExtArgs>
  }, ExtArgs["result"]["reportCoReporter"]>

  export type ReportCoReporterSelectScalar = {
    id?: boolean
    createdAt?: boolean
    reportId?: boolean
    userId?: boolean
  }

  export type ReportCoReporterOmit<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = $Extensions.GetOmit<"id" | "createdAt" | "reportId" | "userId", ExtArgs["result"]["reportCoReporter"]>
  export type ReportCoReporterInclude<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    report?: boolean | ReportDefaultArgs<ExtArgs>
    user?: boolean | UserDefaultArgs<ExtArgs>
  }
  export type ReportCoReporterIncludeCreateManyAndReturn<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    report?: boolean | ReportDefaultArgs<ExtArgs>
    user?: boolean | UserDefaultArgs<ExtArgs>
  }
  export type ReportCoReporterIncludeUpdateManyAndReturn<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    report?: boolean | ReportDefaultArgs<ExtArgs>
    user?: boolean | UserDefaultArgs<ExtArgs>
  }

  export type $ReportCoReporterPayload<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    name: "ReportCoReporter"
    objects: {
      report: Prisma.$ReportPayload<ExtArgs>
      user: Prisma.$UserPayload<ExtArgs>
    }
    scalars: $Extensions.GetPayloadResult<{
      id: string
      createdAt: Date
      reportId: string
      userId: string
    }, ExtArgs["result"]["reportCoReporter"]>
    composites: {}
  }

  type ReportCoReporterGetPayload<S extends boolean | null | undefined | ReportCoReporterDefaultArgs> = $Result.GetResult<Prisma.$ReportCoReporterPayload, S>

  type ReportCoReporterCountArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> =
    Omit<ReportCoReporterFindManyArgs, 'select' | 'include' | 'distinct' | 'omit'> & {
      select?: ReportCoReporterCountAggregateInputType | true
    }

  export interface ReportCoReporterDelegate<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs, GlobalOmitOptions = {}> {
    [K: symbol]: { types: Prisma.TypeMap<ExtArgs>['model']['ReportCoReporter'], meta: { name: 'ReportCoReporter' } }
    /**
     * Find zero or one ReportCoReporter that matches the filter.
     * @param {ReportCoReporterFindUniqueArgs} args - Arguments to find a ReportCoReporter
     * @example
     * // Get one ReportCoReporter
     * const reportCoReporter = await prisma.reportCoReporter.findUnique({
     *   where: {
     *     // ... provide filter here
     *   }
     * })
     */
    findUnique<T extends ReportCoReporterFindUniqueArgs>(args: SelectSubset<T, ReportCoReporterFindUniqueArgs<ExtArgs>>): Prisma__ReportCoReporterClient<$Result.GetResult<Prisma.$ReportCoReporterPayload<ExtArgs>, T, "findUnique", GlobalOmitOptions> | null, null, ExtArgs, GlobalOmitOptions>

    /**
     * Find one ReportCoReporter that matches the filter or throw an error with `error.code='P2025'`
     * if no matches were found.
     * @param {ReportCoReporterFindUniqueOrThrowArgs} args - Arguments to find a ReportCoReporter
     * @example
     * // Get one ReportCoReporter
     * const reportCoReporter = await prisma.reportCoReporter.findUniqueOrThrow({
     *   where: {
     *     // ... provide filter here
     *   }
     * })
     */
    findUniqueOrThrow<T extends ReportCoReporterFindUniqueOrThrowArgs>(args: SelectSubset<T, ReportCoReporterFindUniqueOrThrowArgs<ExtArgs>>): Prisma__ReportCoReporterClient<$Result.GetResult<Prisma.$ReportCoReporterPayload<ExtArgs>, T, "findUniqueOrThrow", GlobalOmitOptions>, never, ExtArgs, GlobalOmitOptions>

    /**
     * Find the first ReportCoReporter that matches the filter.
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * @param {ReportCoReporterFindFirstArgs} args - Arguments to find a ReportCoReporter
     * @example
     * // Get one ReportCoReporter
     * const reportCoReporter = await prisma.reportCoReporter.findFirst({
     *   where: {
     *     // ... provide filter here
     *   }
     * })
     */
    findFirst<T extends ReportCoReporterFindFirstArgs>(args?: SelectSubset<T, ReportCoReporterFindFirstArgs<ExtArgs>>): Prisma__ReportCoReporterClient<$Result.GetResult<Prisma.$ReportCoReporterPayload<ExtArgs>, T, "findFirst", GlobalOmitOptions> | null, null, ExtArgs, GlobalOmitOptions>

    /**
     * Find the first ReportCoReporter that matches the filter or
     * throw `PrismaKnownClientError` with `P2025` code if no matches were found.
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * @param {ReportCoReporterFindFirstOrThrowArgs} args - Arguments to find a ReportCoReporter
     * @example
     * // Get one ReportCoReporter
     * const reportCoReporter = await prisma.reportCoReporter.findFirstOrThrow({
     *   where: {
     *     // ... provide filter here
     *   }
     * })
     */
    findFirstOrThrow<T extends ReportCoReporterFindFirstOrThrowArgs>(args?: SelectSubset<T, ReportCoReporterFindFirstOrThrowArgs<ExtArgs>>): Prisma__ReportCoReporterClient<$Result.GetResult<Prisma.$ReportCoReporterPayload<ExtArgs>, T, "findFirstOrThrow", GlobalOmitOptions>, never, ExtArgs, GlobalOmitOptions>

    /**
     * Find zero or more ReportCoReporters that matches the filter.
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * @param {ReportCoReporterFindManyArgs} args - Arguments to filter and select certain fields only.
     * @example
     * // Get all ReportCoReporters
     * const reportCoReporters = await prisma.reportCoReporter.findMany()
     * 
     * // Get first 10 ReportCoReporters
     * const reportCoReporters = await prisma.reportCoReporter.findMany({ take: 10 })
     * 
     * // Only select the `id`
     * const reportCoReporterWithIdOnly = await prisma.reportCoReporter.findMany({ select: { id: true } })
     * 
     */
    findMany<T extends ReportCoReporterFindManyArgs>(args?: SelectSubset<T, ReportCoReporterFindManyArgs<ExtArgs>>): Prisma.PrismaPromise<$Result.GetResult<Prisma.$ReportCoReporterPayload<ExtArgs>, T, "findMany", GlobalOmitOptions>>

    /**
     * Create a ReportCoReporter.
     * @param {ReportCoReporterCreateArgs} args - Arguments to create a ReportCoReporter.
     * @example
     * // Create one ReportCoReporter
     * const ReportCoReporter = await prisma.reportCoReporter.create({
     *   data: {
     *     // ... data to create a ReportCoReporter
     *   }
     * })
     * 
     */
    create<T extends ReportCoReporterCreateArgs>(args: SelectSubset<T, ReportCoReporterCreateArgs<ExtArgs>>): Prisma__ReportCoReporterClient<$Result.GetResult<Prisma.$ReportCoReporterPayload<ExtArgs>, T, "create", GlobalOmitOptions>, never, ExtArgs, GlobalOmitOptions>

    /**
     * Create many ReportCoReporters.
     * @param {ReportCoReporterCreateManyArgs} args - Arguments to create many ReportCoReporters.
     * @example
     * // Create many ReportCoReporters
     * const reportCoReporter = await prisma.reportCoReporter.createMany({
     *   data: [
     *     // ... provide data here
     *   ]
     * })
     *     
     */
    createMany<T extends ReportCoReporterCreateManyArgs>(args?: SelectSubset<T, ReportCoReporterCreateManyArgs<ExtArgs>>): Prisma.PrismaPromise<BatchPayload>

    /**
     * Create many ReportCoReporters and returns the data saved in the database.
     * @param {ReportCoReporterCreateManyAndReturnArgs} args - Arguments to create many ReportCoReporters.
     * @example
     * // Create many ReportCoReporters
     * const reportCoReporter = await prisma.reportCoReporter.createManyAndReturn({
     *   data: [
     *     // ... provide data here
     *   ]
     * })
     * 
     * // Create many ReportCoReporters and only return the `id`
     * const reportCoReporterWithIdOnly = await prisma.reportCoReporter.createManyAndReturn({
     *   select: { id: true },
     *   data: [
     *     // ... provide data here
     *   ]
     * })
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * 
     */
    createManyAndReturn<T extends ReportCoReporterCreateManyAndReturnArgs>(args?: SelectSubset<T, ReportCoReporterCreateManyAndReturnArgs<ExtArgs>>): Prisma.PrismaPromise<$Result.GetResult<Prisma.$ReportCoReporterPayload<ExtArgs>, T, "createManyAndReturn", GlobalOmitOptions>>

    /**
     * Delete a ReportCoReporter.
     * @param {ReportCoReporterDeleteArgs} args - Arguments to delete one ReportCoReporter.
     * @example
     * // Delete one ReportCoReporter
     * const ReportCoReporter = await prisma.reportCoReporter.delete({
     *   where: {
     *     // ... filter to delete one ReportCoReporter
     *   }
     * })
     * 
     */
    delete<T extends ReportCoReporterDeleteArgs>(args: SelectSubset<T, ReportCoReporterDeleteArgs<ExtArgs>>): Prisma__ReportCoReporterClient<$Result.GetResult<Prisma.$ReportCoReporterPayload<ExtArgs>, T, "delete", GlobalOmitOptions>, never, ExtArgs, GlobalOmitOptions>

    /**
     * Update one ReportCoReporter.
     * @param {ReportCoReporterUpdateArgs} args - Arguments to update one ReportCoReporter.
     * @example
     * // Update one ReportCoReporter
     * const reportCoReporter = await prisma.reportCoReporter.update({
     *   where: {
     *     // ... provide filter here
     *   },
     *   data: {
     *     // ... provide data here
     *   }
     * })
     * 
     */
    update<T extends ReportCoReporterUpdateArgs>(args: SelectSubset<T, ReportCoReporterUpdateArgs<ExtArgs>>): Prisma__ReportCoReporterClient<$Result.GetResult<Prisma.$ReportCoReporterPayload<ExtArgs>, T, "update", GlobalOmitOptions>, never, ExtArgs, GlobalOmitOptions>

    /**
     * Delete zero or more ReportCoReporters.
     * @param {ReportCoReporterDeleteManyArgs} args - Arguments to filter ReportCoReporters to delete.
     * @example
     * // Delete a few ReportCoReporters
     * const { count } = await prisma.reportCoReporter.deleteMany({
     *   where: {
     *     // ... provide filter here
     *   }
     * })
     * 
     */
    deleteMany<T extends ReportCoReporterDeleteManyArgs>(args?: SelectSubset<T, ReportCoReporterDeleteManyArgs<ExtArgs>>): Prisma.PrismaPromise<BatchPayload>

    /**
     * Update zero or more ReportCoReporters.
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * @param {ReportCoReporterUpdateManyArgs} args - Arguments to update one or more rows.
     * @example
     * // Update many ReportCoReporters
     * const reportCoReporter = await prisma.reportCoReporter.updateMany({
     *   where: {
     *     // ... provide filter here
     *   },
     *   data: {
     *     // ... provide data here
     *   }
     * })
     * 
     */
    updateMany<T extends ReportCoReporterUpdateManyArgs>(args: SelectSubset<T, ReportCoReporterUpdateManyArgs<ExtArgs>>): Prisma.PrismaPromise<BatchPayload>

    /**
     * Update zero or more ReportCoReporters and returns the data updated in the database.
     * @param {ReportCoReporterUpdateManyAndReturnArgs} args - Arguments to update many ReportCoReporters.
     * @example
     * // Update many ReportCoReporters
     * const reportCoReporter = await prisma.reportCoReporter.updateManyAndReturn({
     *   where: {
     *     // ... provide filter here
     *   },
     *   data: [
     *     // ... provide data here
     *   ]
     * })
     * 
     * // Update zero or more ReportCoReporters and only return the `id`
     * const reportCoReporterWithIdOnly = await prisma.reportCoReporter.updateManyAndReturn({
     *   select: { id: true },
     *   where: {
     *     // ... provide filter here
     *   },
     *   data: [
     *     // ... provide data here
     *   ]
     * })
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * 
     */
    updateManyAndReturn<T extends ReportCoReporterUpdateManyAndReturnArgs>(args: SelectSubset<T, ReportCoReporterUpdateManyAndReturnArgs<ExtArgs>>): Prisma.PrismaPromise<$Result.GetResult<Prisma.$ReportCoReporterPayload<ExtArgs>, T, "updateManyAndReturn", GlobalOmitOptions>>

    /**
     * Create or update one ReportCoReporter.
     * @param {ReportCoReporterUpsertArgs} args - Arguments to update or create a ReportCoReporter.
     * @example
     * // Update or create a ReportCoReporter
     * const reportCoReporter = await prisma.reportCoReporter.upsert({
     *   create: {
     *     // ... data to create a ReportCoReporter
     *   },
     *   update: {
     *     // ... in case it already exists, update
     *   },
     *   where: {
     *     // ... the filter for the ReportCoReporter we want to update
     *   }
     * })
     */
    upsert<T extends ReportCoReporterUpsertArgs>(args: SelectSubset<T, ReportCoReporterUpsertArgs<ExtArgs>>): Prisma__ReportCoReporterClient<$Result.GetResult<Prisma.$ReportCoReporterPayload<ExtArgs>, T, "upsert", GlobalOmitOptions>, never, ExtArgs, GlobalOmitOptions>


    /**
     * Count the number of ReportCoReporters.
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * @param {ReportCoReporterCountArgs} args - Arguments to filter ReportCoReporters to count.
     * @example
     * // Count the number of ReportCoReporters
     * const count = await prisma.reportCoReporter.count({
     *   where: {
     *     // ... the filter for the ReportCoReporters we want to count
     *   }
     * })
    **/
    count<T extends ReportCoReporterCountArgs>(
      args?: Subset<T, ReportCoReporterCountArgs>,
    ): Prisma.PrismaPromise<
      T extends $Utils.Record<'select', any>
        ? T['select'] extends true
          ? number
          : GetScalarType<T['select'], ReportCoReporterCountAggregateOutputType>
        : number
    >

    /**
     * Allows you to perform aggregations operations on a ReportCoReporter.
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * @param {ReportCoReporterAggregateArgs} args - Select which aggregations you would like to apply and on what fields.
     * @example
     * // Ordered by age ascending
     * // Where email contains prisma.io
     * // Limited to the 10 users
     * const aggregations = await prisma.user.aggregate({
     *   _avg: {
     *     age: true,
     *   },
     *   where: {
     *     email: {
     *       contains: "prisma.io",
     *     },
     *   },
     *   orderBy: {
     *     age: "asc",
     *   },
     *   take: 10,
     * })
    **/
    aggregate<T extends ReportCoReporterAggregateArgs>(args: Subset<T, ReportCoReporterAggregateArgs>): Prisma.PrismaPromise<GetReportCoReporterAggregateType<T>>

    /**
     * Group by ReportCoReporter.
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * @param {ReportCoReporterGroupByArgs} args - Group by arguments.
     * @example
     * // Group by city, order by createdAt, get count
     * const result = await prisma.user.groupBy({
     *   by: ['city', 'createdAt'],
     *   orderBy: {
     *     createdAt: true
     *   },
     *   _count: {
     *     _all: true
     *   },
     * })
     * 
    **/
    groupBy<
      T extends ReportCoReporterGroupByArgs,
      HasSelectOrTake extends Or<
        Extends<'skip', Keys<T>>,
        Extends<'take', Keys<T>>
      >,
      OrderByArg extends True extends HasSelectOrTake
        ? { orderBy: ReportCoReporterGroupByArgs['orderBy'] }
        : { orderBy?: ReportCoReporterGroupByArgs['orderBy'] },
      OrderFields extends ExcludeUnderscoreKeys<Keys<MaybeTupleToUnion<T['orderBy']>>>,
      ByFields extends MaybeTupleToUnion<T['by']>,
      ByValid extends Has<ByFields, OrderFields>,
      HavingFields extends GetHavingFields<T['having']>,
      HavingValid extends Has<ByFields, HavingFields>,
      ByEmpty extends T['by'] extends never[] ? True : False,
      InputErrors extends ByEmpty extends True
      ? `Error: "by" must not be empty.`
      : HavingValid extends False
      ? {
          [P in HavingFields]: P extends ByFields
            ? never
            : P extends string
            ? `Error: Field "${P}" used in "having" needs to be provided in "by".`
            : [
                Error,
                'Field ',
                P,
                ` in "having" needs to be provided in "by"`,
              ]
        }[HavingFields]
      : 'take' extends Keys<T>
      ? 'orderBy' extends Keys<T>
        ? ByValid extends True
          ? {}
          : {
              [P in OrderFields]: P extends ByFields
                ? never
                : `Error: Field "${P}" in "orderBy" needs to be provided in "by"`
            }[OrderFields]
        : 'Error: If you provide "take", you also need to provide "orderBy"'
      : 'skip' extends Keys<T>
      ? 'orderBy' extends Keys<T>
        ? ByValid extends True
          ? {}
          : {
              [P in OrderFields]: P extends ByFields
                ? never
                : `Error: Field "${P}" in "orderBy" needs to be provided in "by"`
            }[OrderFields]
        : 'Error: If you provide "skip", you also need to provide "orderBy"'
      : ByValid extends True
      ? {}
      : {
          [P in OrderFields]: P extends ByFields
            ? never
            : `Error: Field "${P}" in "orderBy" needs to be provided in "by"`
        }[OrderFields]
    >(args: SubsetIntersection<T, ReportCoReporterGroupByArgs, OrderByArg> & InputErrors): {} extends InputErrors ? GetReportCoReporterGroupByPayload<T> : Prisma.PrismaPromise<InputErrors>
  /**
   * Fields of the ReportCoReporter model
   */
  readonly fields: ReportCoReporterFieldRefs;
  }

  /**
   * The delegate class that acts as a "Promise-like" for ReportCoReporter.
   * Why is this prefixed with `Prisma__`?
   * Because we want to prevent naming conflicts as mentioned in
   * https://github.com/prisma/prisma-client-js/issues/707
   */
  export interface Prisma__ReportCoReporterClient<T, Null = never, ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs, GlobalOmitOptions = {}> extends Prisma.PrismaPromise<T> {
    readonly [Symbol.toStringTag]: "PrismaPromise"
    report<T extends ReportDefaultArgs<ExtArgs> = {}>(args?: Subset<T, ReportDefaultArgs<ExtArgs>>): Prisma__ReportClient<$Result.GetResult<Prisma.$ReportPayload<ExtArgs>, T, "findUniqueOrThrow", GlobalOmitOptions> | Null, Null, ExtArgs, GlobalOmitOptions>
    user<T extends UserDefaultArgs<ExtArgs> = {}>(args?: Subset<T, UserDefaultArgs<ExtArgs>>): Prisma__UserClient<$Result.GetResult<Prisma.$UserPayload<ExtArgs>, T, "findUniqueOrThrow", GlobalOmitOptions> | Null, Null, ExtArgs, GlobalOmitOptions>
    /**
     * Attaches callbacks for the resolution and/or rejection of the Promise.
     * @param onfulfilled The callback to execute when the Promise is resolved.
     * @param onrejected The callback to execute when the Promise is rejected.
     * @returns A Promise for the completion of which ever callback is executed.
     */
    then<TResult1 = T, TResult2 = never>(onfulfilled?: ((value: T) => TResult1 | PromiseLike<TResult1>) | undefined | null, onrejected?: ((reason: any) => TResult2 | PromiseLike<TResult2>) | undefined | null): $Utils.JsPromise<TResult1 | TResult2>
    /**
     * Attaches a callback for only the rejection of the Promise.
     * @param onrejected The callback to execute when the Promise is rejected.
     * @returns A Promise for the completion of the callback.
     */
    catch<TResult = never>(onrejected?: ((reason: any) => TResult | PromiseLike<TResult>) | undefined | null): $Utils.JsPromise<T | TResult>
    /**
     * Attaches a callback that is invoked when the Promise is settled (fulfilled or rejected). The
     * resolved value cannot be modified from the callback.
     * @param onfinally The callback to execute when the Promise is settled (fulfilled or rejected).
     * @returns A Promise for the completion of the callback.
     */
    finally(onfinally?: (() => void) | undefined | null): $Utils.JsPromise<T>
  }




  /**
   * Fields of the ReportCoReporter model
   */
  interface ReportCoReporterFieldRefs {
    readonly id: FieldRef<"ReportCoReporter", 'String'>
    readonly createdAt: FieldRef<"ReportCoReporter", 'DateTime'>
    readonly reportId: FieldRef<"ReportCoReporter", 'String'>
    readonly userId: FieldRef<"ReportCoReporter", 'String'>
  }
    

  // Custom InputTypes
  /**
   * ReportCoReporter findUnique
   */
  export type ReportCoReporterFindUniqueArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the ReportCoReporter
     */
    select?: ReportCoReporterSelect<ExtArgs> | null
    /**
     * Omit specific fields from the ReportCoReporter
     */
    omit?: ReportCoReporterOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: ReportCoReporterInclude<ExtArgs> | null
    /**
     * Filter, which ReportCoReporter to fetch.
     */
    where: ReportCoReporterWhereUniqueInput
  }

  /**
   * ReportCoReporter findUniqueOrThrow
   */
  export type ReportCoReporterFindUniqueOrThrowArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the ReportCoReporter
     */
    select?: ReportCoReporterSelect<ExtArgs> | null
    /**
     * Omit specific fields from the ReportCoReporter
     */
    omit?: ReportCoReporterOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: ReportCoReporterInclude<ExtArgs> | null
    /**
     * Filter, which ReportCoReporter to fetch.
     */
    where: ReportCoReporterWhereUniqueInput
  }

  /**
   * ReportCoReporter findFirst
   */
  export type ReportCoReporterFindFirstArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the ReportCoReporter
     */
    select?: ReportCoReporterSelect<ExtArgs> | null
    /**
     * Omit specific fields from the ReportCoReporter
     */
    omit?: ReportCoReporterOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: ReportCoReporterInclude<ExtArgs> | null
    /**
     * Filter, which ReportCoReporter to fetch.
     */
    where?: ReportCoReporterWhereInput
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/sorting Sorting Docs}
     * 
     * Determine the order of ReportCoReporters to fetch.
     */
    orderBy?: ReportCoReporterOrderByWithRelationInput | ReportCoReporterOrderByWithRelationInput[]
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination#cursor-based-pagination Cursor Docs}
     * 
     * Sets the position for searching for ReportCoReporters.
     */
    cursor?: ReportCoReporterWhereUniqueInput
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination Pagination Docs}
     * 
     * Take `±n` ReportCoReporters from the position of the cursor.
     */
    take?: number
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination Pagination Docs}
     * 
     * Skip the first `n` ReportCoReporters.
     */
    skip?: number
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/distinct Distinct Docs}
     * 
     * Filter by unique combinations of ReportCoReporters.
     */
    distinct?: ReportCoReporterScalarFieldEnum | ReportCoReporterScalarFieldEnum[]
  }

  /**
   * ReportCoReporter findFirstOrThrow
   */
  export type ReportCoReporterFindFirstOrThrowArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the ReportCoReporter
     */
    select?: ReportCoReporterSelect<ExtArgs> | null
    /**
     * Omit specific fields from the ReportCoReporter
     */
    omit?: ReportCoReporterOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: ReportCoReporterInclude<ExtArgs> | null
    /**
     * Filter, which ReportCoReporter to fetch.
     */
    where?: ReportCoReporterWhereInput
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/sorting Sorting Docs}
     * 
     * Determine the order of ReportCoReporters to fetch.
     */
    orderBy?: ReportCoReporterOrderByWithRelationInput | ReportCoReporterOrderByWithRelationInput[]
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination#cursor-based-pagination Cursor Docs}
     * 
     * Sets the position for searching for ReportCoReporters.
     */
    cursor?: ReportCoReporterWhereUniqueInput
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination Pagination Docs}
     * 
     * Take `±n` ReportCoReporters from the position of the cursor.
     */
    take?: number
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination Pagination Docs}
     * 
     * Skip the first `n` ReportCoReporters.
     */
    skip?: number
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/distinct Distinct Docs}
     * 
     * Filter by unique combinations of ReportCoReporters.
     */
    distinct?: ReportCoReporterScalarFieldEnum | ReportCoReporterScalarFieldEnum[]
  }

  /**
   * ReportCoReporter findMany
   */
  export type ReportCoReporterFindManyArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the ReportCoReporter
     */
    select?: ReportCoReporterSelect<ExtArgs> | null
    /**
     * Omit specific fields from the ReportCoReporter
     */
    omit?: ReportCoReporterOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: ReportCoReporterInclude<ExtArgs> | null
    /**
     * Filter, which ReportCoReporters to fetch.
     */
    where?: ReportCoReporterWhereInput
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/sorting Sorting Docs}
     * 
     * Determine the order of ReportCoReporters to fetch.
     */
    orderBy?: ReportCoReporterOrderByWithRelationInput | ReportCoReporterOrderByWithRelationInput[]
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination#cursor-based-pagination Cursor Docs}
     * 
     * Sets the position for listing ReportCoReporters.
     */
    cursor?: ReportCoReporterWhereUniqueInput
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination Pagination Docs}
     * 
     * Take `±n` ReportCoReporters from the position of the cursor.
     */
    take?: number
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination Pagination Docs}
     * 
     * Skip the first `n` ReportCoReporters.
     */
    skip?: number
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/distinct Distinct Docs}
     * 
     * Filter by unique combinations of ReportCoReporters.
     */
    distinct?: ReportCoReporterScalarFieldEnum | ReportCoReporterScalarFieldEnum[]
  }

  /**
   * ReportCoReporter create
   */
  export type ReportCoReporterCreateArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the ReportCoReporter
     */
    select?: ReportCoReporterSelect<ExtArgs> | null
    /**
     * Omit specific fields from the ReportCoReporter
     */
    omit?: ReportCoReporterOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: ReportCoReporterInclude<ExtArgs> | null
    /**
     * The data needed to create a ReportCoReporter.
     */
    data: XOR<ReportCoReporterCreateInput, ReportCoReporterUncheckedCreateInput>
  }

  /**
   * ReportCoReporter createMany
   */
  export type ReportCoReporterCreateManyArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * The data used to create many ReportCoReporters.
     */
    data: ReportCoReporterCreateManyInput | ReportCoReporterCreateManyInput[]
    skipDuplicates?: boolean
  }

  /**
   * ReportCoReporter createManyAndReturn
   */
  export type ReportCoReporterCreateManyAndReturnArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the ReportCoReporter
     */
    select?: ReportCoReporterSelectCreateManyAndReturn<ExtArgs> | null
    /**
     * Omit specific fields from the ReportCoReporter
     */
    omit?: ReportCoReporterOmit<ExtArgs> | null
    /**
     * The data used to create many ReportCoReporters.
     */
    data: ReportCoReporterCreateManyInput | ReportCoReporterCreateManyInput[]
    skipDuplicates?: boolean
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: ReportCoReporterIncludeCreateManyAndReturn<ExtArgs> | null
  }

  /**
   * ReportCoReporter update
   */
  export type ReportCoReporterUpdateArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the ReportCoReporter
     */
    select?: ReportCoReporterSelect<ExtArgs> | null
    /**
     * Omit specific fields from the ReportCoReporter
     */
    omit?: ReportCoReporterOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: ReportCoReporterInclude<ExtArgs> | null
    /**
     * The data needed to update a ReportCoReporter.
     */
    data: XOR<ReportCoReporterUpdateInput, ReportCoReporterUncheckedUpdateInput>
    /**
     * Choose, which ReportCoReporter to update.
     */
    where: ReportCoReporterWhereUniqueInput
  }

  /**
   * ReportCoReporter updateMany
   */
  export type ReportCoReporterUpdateManyArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * The data used to update ReportCoReporters.
     */
    data: XOR<ReportCoReporterUpdateManyMutationInput, ReportCoReporterUncheckedUpdateManyInput>
    /**
     * Filter which ReportCoReporters to update
     */
    where?: ReportCoReporterWhereInput
    /**
     * Limit how many ReportCoReporters to update.
     */
    limit?: number
  }

  /**
   * ReportCoReporter updateManyAndReturn
   */
  export type ReportCoReporterUpdateManyAndReturnArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the ReportCoReporter
     */
    select?: ReportCoReporterSelectUpdateManyAndReturn<ExtArgs> | null
    /**
     * Omit specific fields from the ReportCoReporter
     */
    omit?: ReportCoReporterOmit<ExtArgs> | null
    /**
     * The data used to update ReportCoReporters.
     */
    data: XOR<ReportCoReporterUpdateManyMutationInput, ReportCoReporterUncheckedUpdateManyInput>
    /**
     * Filter which ReportCoReporters to update
     */
    where?: ReportCoReporterWhereInput
    /**
     * Limit how many ReportCoReporters to update.
     */
    limit?: number
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: ReportCoReporterIncludeUpdateManyAndReturn<ExtArgs> | null
  }

  /**
   * ReportCoReporter upsert
   */
  export type ReportCoReporterUpsertArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the ReportCoReporter
     */
    select?: ReportCoReporterSelect<ExtArgs> | null
    /**
     * Omit specific fields from the ReportCoReporter
     */
    omit?: ReportCoReporterOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: ReportCoReporterInclude<ExtArgs> | null
    /**
     * The filter to search for the ReportCoReporter to update in case it exists.
     */
    where: ReportCoReporterWhereUniqueInput
    /**
     * In case the ReportCoReporter found by the `where` argument doesn't exist, create a new ReportCoReporter with this data.
     */
    create: XOR<ReportCoReporterCreateInput, ReportCoReporterUncheckedCreateInput>
    /**
     * In case the ReportCoReporter was found with the provided `where` argument, update it with this data.
     */
    update: XOR<ReportCoReporterUpdateInput, ReportCoReporterUncheckedUpdateInput>
  }

  /**
   * ReportCoReporter delete
   */
  export type ReportCoReporterDeleteArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the ReportCoReporter
     */
    select?: ReportCoReporterSelect<ExtArgs> | null
    /**
     * Omit specific fields from the ReportCoReporter
     */
    omit?: ReportCoReporterOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: ReportCoReporterInclude<ExtArgs> | null
    /**
     * Filter which ReportCoReporter to delete.
     */
    where: ReportCoReporterWhereUniqueInput
  }

  /**
   * ReportCoReporter deleteMany
   */
  export type ReportCoReporterDeleteManyArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Filter which ReportCoReporters to delete
     */
    where?: ReportCoReporterWhereInput
    /**
     * Limit how many ReportCoReporters to delete.
     */
    limit?: number
  }

  /**
   * ReportCoReporter without action
   */
  export type ReportCoReporterDefaultArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the ReportCoReporter
     */
    select?: ReportCoReporterSelect<ExtArgs> | null
    /**
     * Omit specific fields from the ReportCoReporter
     */
    omit?: ReportCoReporterOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: ReportCoReporterInclude<ExtArgs> | null
  }


  /**
   * Model CleanupEvent
   */

  export type AggregateCleanupEvent = {
    _count: CleanupEventCountAggregateOutputType | null
    _avg: CleanupEventAvgAggregateOutputType | null
    _sum: CleanupEventSumAggregateOutputType | null
    _min: CleanupEventMinAggregateOutputType | null
    _max: CleanupEventMaxAggregateOutputType | null
  }

  export type CleanupEventAvgAggregateOutputType = {
    participantCount: number | null
  }

  export type CleanupEventSumAggregateOutputType = {
    participantCount: number | null
  }

  export type CleanupEventMinAggregateOutputType = {
    id: string | null
    createdAt: Date | null
    updatedAt: Date | null
    siteId: string | null
    scheduledAt: Date | null
    completedAt: Date | null
    organizerId: string | null
    participantCount: number | null
  }

  export type CleanupEventMaxAggregateOutputType = {
    id: string | null
    createdAt: Date | null
    updatedAt: Date | null
    siteId: string | null
    scheduledAt: Date | null
    completedAt: Date | null
    organizerId: string | null
    participantCount: number | null
  }

  export type CleanupEventCountAggregateOutputType = {
    id: number
    createdAt: number
    updatedAt: number
    siteId: number
    scheduledAt: number
    completedAt: number
    organizerId: number
    participantCount: number
    _all: number
  }


  export type CleanupEventAvgAggregateInputType = {
    participantCount?: true
  }

  export type CleanupEventSumAggregateInputType = {
    participantCount?: true
  }

  export type CleanupEventMinAggregateInputType = {
    id?: true
    createdAt?: true
    updatedAt?: true
    siteId?: true
    scheduledAt?: true
    completedAt?: true
    organizerId?: true
    participantCount?: true
  }

  export type CleanupEventMaxAggregateInputType = {
    id?: true
    createdAt?: true
    updatedAt?: true
    siteId?: true
    scheduledAt?: true
    completedAt?: true
    organizerId?: true
    participantCount?: true
  }

  export type CleanupEventCountAggregateInputType = {
    id?: true
    createdAt?: true
    updatedAt?: true
    siteId?: true
    scheduledAt?: true
    completedAt?: true
    organizerId?: true
    participantCount?: true
    _all?: true
  }

  export type CleanupEventAggregateArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Filter which CleanupEvent to aggregate.
     */
    where?: CleanupEventWhereInput
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/sorting Sorting Docs}
     * 
     * Determine the order of CleanupEvents to fetch.
     */
    orderBy?: CleanupEventOrderByWithRelationInput | CleanupEventOrderByWithRelationInput[]
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination#cursor-based-pagination Cursor Docs}
     * 
     * Sets the start position
     */
    cursor?: CleanupEventWhereUniqueInput
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination Pagination Docs}
     * 
     * Take `±n` CleanupEvents from the position of the cursor.
     */
    take?: number
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination Pagination Docs}
     * 
     * Skip the first `n` CleanupEvents.
     */
    skip?: number
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/aggregations Aggregation Docs}
     * 
     * Count returned CleanupEvents
    **/
    _count?: true | CleanupEventCountAggregateInputType
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/aggregations Aggregation Docs}
     * 
     * Select which fields to average
    **/
    _avg?: CleanupEventAvgAggregateInputType
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/aggregations Aggregation Docs}
     * 
     * Select which fields to sum
    **/
    _sum?: CleanupEventSumAggregateInputType
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/aggregations Aggregation Docs}
     * 
     * Select which fields to find the minimum value
    **/
    _min?: CleanupEventMinAggregateInputType
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/aggregations Aggregation Docs}
     * 
     * Select which fields to find the maximum value
    **/
    _max?: CleanupEventMaxAggregateInputType
  }

  export type GetCleanupEventAggregateType<T extends CleanupEventAggregateArgs> = {
        [P in keyof T & keyof AggregateCleanupEvent]: P extends '_count' | 'count'
      ? T[P] extends true
        ? number
        : GetScalarType<T[P], AggregateCleanupEvent[P]>
      : GetScalarType<T[P], AggregateCleanupEvent[P]>
  }




  export type CleanupEventGroupByArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    where?: CleanupEventWhereInput
    orderBy?: CleanupEventOrderByWithAggregationInput | CleanupEventOrderByWithAggregationInput[]
    by: CleanupEventScalarFieldEnum[] | CleanupEventScalarFieldEnum
    having?: CleanupEventScalarWhereWithAggregatesInput
    take?: number
    skip?: number
    _count?: CleanupEventCountAggregateInputType | true
    _avg?: CleanupEventAvgAggregateInputType
    _sum?: CleanupEventSumAggregateInputType
    _min?: CleanupEventMinAggregateInputType
    _max?: CleanupEventMaxAggregateInputType
  }

  export type CleanupEventGroupByOutputType = {
    id: string
    createdAt: Date
    updatedAt: Date
    siteId: string
    scheduledAt: Date
    completedAt: Date | null
    organizerId: string | null
    participantCount: number
    _count: CleanupEventCountAggregateOutputType | null
    _avg: CleanupEventAvgAggregateOutputType | null
    _sum: CleanupEventSumAggregateOutputType | null
    _min: CleanupEventMinAggregateOutputType | null
    _max: CleanupEventMaxAggregateOutputType | null
  }

  type GetCleanupEventGroupByPayload<T extends CleanupEventGroupByArgs> = Prisma.PrismaPromise<
    Array<
      PickEnumerable<CleanupEventGroupByOutputType, T['by']> &
        {
          [P in ((keyof T) & (keyof CleanupEventGroupByOutputType))]: P extends '_count'
            ? T[P] extends boolean
              ? number
              : GetScalarType<T[P], CleanupEventGroupByOutputType[P]>
            : GetScalarType<T[P], CleanupEventGroupByOutputType[P]>
        }
      >
    >


  export type CleanupEventSelect<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = $Extensions.GetSelect<{
    id?: boolean
    createdAt?: boolean
    updatedAt?: boolean
    siteId?: boolean
    scheduledAt?: boolean
    completedAt?: boolean
    organizerId?: boolean
    participantCount?: boolean
    site?: boolean | SiteDefaultArgs<ExtArgs>
  }, ExtArgs["result"]["cleanupEvent"]>

  export type CleanupEventSelectCreateManyAndReturn<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = $Extensions.GetSelect<{
    id?: boolean
    createdAt?: boolean
    updatedAt?: boolean
    siteId?: boolean
    scheduledAt?: boolean
    completedAt?: boolean
    organizerId?: boolean
    participantCount?: boolean
    site?: boolean | SiteDefaultArgs<ExtArgs>
  }, ExtArgs["result"]["cleanupEvent"]>

  export type CleanupEventSelectUpdateManyAndReturn<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = $Extensions.GetSelect<{
    id?: boolean
    createdAt?: boolean
    updatedAt?: boolean
    siteId?: boolean
    scheduledAt?: boolean
    completedAt?: boolean
    organizerId?: boolean
    participantCount?: boolean
    site?: boolean | SiteDefaultArgs<ExtArgs>
  }, ExtArgs["result"]["cleanupEvent"]>

  export type CleanupEventSelectScalar = {
    id?: boolean
    createdAt?: boolean
    updatedAt?: boolean
    siteId?: boolean
    scheduledAt?: boolean
    completedAt?: boolean
    organizerId?: boolean
    participantCount?: boolean
  }

  export type CleanupEventOmit<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = $Extensions.GetOmit<"id" | "createdAt" | "updatedAt" | "siteId" | "scheduledAt" | "completedAt" | "organizerId" | "participantCount", ExtArgs["result"]["cleanupEvent"]>
  export type CleanupEventInclude<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    site?: boolean | SiteDefaultArgs<ExtArgs>
  }
  export type CleanupEventIncludeCreateManyAndReturn<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    site?: boolean | SiteDefaultArgs<ExtArgs>
  }
  export type CleanupEventIncludeUpdateManyAndReturn<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    site?: boolean | SiteDefaultArgs<ExtArgs>
  }

  export type $CleanupEventPayload<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    name: "CleanupEvent"
    objects: {
      site: Prisma.$SitePayload<ExtArgs>
    }
    scalars: $Extensions.GetPayloadResult<{
      id: string
      createdAt: Date
      updatedAt: Date
      siteId: string
      scheduledAt: Date
      completedAt: Date | null
      organizerId: string | null
      participantCount: number
    }, ExtArgs["result"]["cleanupEvent"]>
    composites: {}
  }

  type CleanupEventGetPayload<S extends boolean | null | undefined | CleanupEventDefaultArgs> = $Result.GetResult<Prisma.$CleanupEventPayload, S>

  type CleanupEventCountArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> =
    Omit<CleanupEventFindManyArgs, 'select' | 'include' | 'distinct' | 'omit'> & {
      select?: CleanupEventCountAggregateInputType | true
    }

  export interface CleanupEventDelegate<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs, GlobalOmitOptions = {}> {
    [K: symbol]: { types: Prisma.TypeMap<ExtArgs>['model']['CleanupEvent'], meta: { name: 'CleanupEvent' } }
    /**
     * Find zero or one CleanupEvent that matches the filter.
     * @param {CleanupEventFindUniqueArgs} args - Arguments to find a CleanupEvent
     * @example
     * // Get one CleanupEvent
     * const cleanupEvent = await prisma.cleanupEvent.findUnique({
     *   where: {
     *     // ... provide filter here
     *   }
     * })
     */
    findUnique<T extends CleanupEventFindUniqueArgs>(args: SelectSubset<T, CleanupEventFindUniqueArgs<ExtArgs>>): Prisma__CleanupEventClient<$Result.GetResult<Prisma.$CleanupEventPayload<ExtArgs>, T, "findUnique", GlobalOmitOptions> | null, null, ExtArgs, GlobalOmitOptions>

    /**
     * Find one CleanupEvent that matches the filter or throw an error with `error.code='P2025'`
     * if no matches were found.
     * @param {CleanupEventFindUniqueOrThrowArgs} args - Arguments to find a CleanupEvent
     * @example
     * // Get one CleanupEvent
     * const cleanupEvent = await prisma.cleanupEvent.findUniqueOrThrow({
     *   where: {
     *     // ... provide filter here
     *   }
     * })
     */
    findUniqueOrThrow<T extends CleanupEventFindUniqueOrThrowArgs>(args: SelectSubset<T, CleanupEventFindUniqueOrThrowArgs<ExtArgs>>): Prisma__CleanupEventClient<$Result.GetResult<Prisma.$CleanupEventPayload<ExtArgs>, T, "findUniqueOrThrow", GlobalOmitOptions>, never, ExtArgs, GlobalOmitOptions>

    /**
     * Find the first CleanupEvent that matches the filter.
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * @param {CleanupEventFindFirstArgs} args - Arguments to find a CleanupEvent
     * @example
     * // Get one CleanupEvent
     * const cleanupEvent = await prisma.cleanupEvent.findFirst({
     *   where: {
     *     // ... provide filter here
     *   }
     * })
     */
    findFirst<T extends CleanupEventFindFirstArgs>(args?: SelectSubset<T, CleanupEventFindFirstArgs<ExtArgs>>): Prisma__CleanupEventClient<$Result.GetResult<Prisma.$CleanupEventPayload<ExtArgs>, T, "findFirst", GlobalOmitOptions> | null, null, ExtArgs, GlobalOmitOptions>

    /**
     * Find the first CleanupEvent that matches the filter or
     * throw `PrismaKnownClientError` with `P2025` code if no matches were found.
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * @param {CleanupEventFindFirstOrThrowArgs} args - Arguments to find a CleanupEvent
     * @example
     * // Get one CleanupEvent
     * const cleanupEvent = await prisma.cleanupEvent.findFirstOrThrow({
     *   where: {
     *     // ... provide filter here
     *   }
     * })
     */
    findFirstOrThrow<T extends CleanupEventFindFirstOrThrowArgs>(args?: SelectSubset<T, CleanupEventFindFirstOrThrowArgs<ExtArgs>>): Prisma__CleanupEventClient<$Result.GetResult<Prisma.$CleanupEventPayload<ExtArgs>, T, "findFirstOrThrow", GlobalOmitOptions>, never, ExtArgs, GlobalOmitOptions>

    /**
     * Find zero or more CleanupEvents that matches the filter.
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * @param {CleanupEventFindManyArgs} args - Arguments to filter and select certain fields only.
     * @example
     * // Get all CleanupEvents
     * const cleanupEvents = await prisma.cleanupEvent.findMany()
     * 
     * // Get first 10 CleanupEvents
     * const cleanupEvents = await prisma.cleanupEvent.findMany({ take: 10 })
     * 
     * // Only select the `id`
     * const cleanupEventWithIdOnly = await prisma.cleanupEvent.findMany({ select: { id: true } })
     * 
     */
    findMany<T extends CleanupEventFindManyArgs>(args?: SelectSubset<T, CleanupEventFindManyArgs<ExtArgs>>): Prisma.PrismaPromise<$Result.GetResult<Prisma.$CleanupEventPayload<ExtArgs>, T, "findMany", GlobalOmitOptions>>

    /**
     * Create a CleanupEvent.
     * @param {CleanupEventCreateArgs} args - Arguments to create a CleanupEvent.
     * @example
     * // Create one CleanupEvent
     * const CleanupEvent = await prisma.cleanupEvent.create({
     *   data: {
     *     // ... data to create a CleanupEvent
     *   }
     * })
     * 
     */
    create<T extends CleanupEventCreateArgs>(args: SelectSubset<T, CleanupEventCreateArgs<ExtArgs>>): Prisma__CleanupEventClient<$Result.GetResult<Prisma.$CleanupEventPayload<ExtArgs>, T, "create", GlobalOmitOptions>, never, ExtArgs, GlobalOmitOptions>

    /**
     * Create many CleanupEvents.
     * @param {CleanupEventCreateManyArgs} args - Arguments to create many CleanupEvents.
     * @example
     * // Create many CleanupEvents
     * const cleanupEvent = await prisma.cleanupEvent.createMany({
     *   data: [
     *     // ... provide data here
     *   ]
     * })
     *     
     */
    createMany<T extends CleanupEventCreateManyArgs>(args?: SelectSubset<T, CleanupEventCreateManyArgs<ExtArgs>>): Prisma.PrismaPromise<BatchPayload>

    /**
     * Create many CleanupEvents and returns the data saved in the database.
     * @param {CleanupEventCreateManyAndReturnArgs} args - Arguments to create many CleanupEvents.
     * @example
     * // Create many CleanupEvents
     * const cleanupEvent = await prisma.cleanupEvent.createManyAndReturn({
     *   data: [
     *     // ... provide data here
     *   ]
     * })
     * 
     * // Create many CleanupEvents and only return the `id`
     * const cleanupEventWithIdOnly = await prisma.cleanupEvent.createManyAndReturn({
     *   select: { id: true },
     *   data: [
     *     // ... provide data here
     *   ]
     * })
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * 
     */
    createManyAndReturn<T extends CleanupEventCreateManyAndReturnArgs>(args?: SelectSubset<T, CleanupEventCreateManyAndReturnArgs<ExtArgs>>): Prisma.PrismaPromise<$Result.GetResult<Prisma.$CleanupEventPayload<ExtArgs>, T, "createManyAndReturn", GlobalOmitOptions>>

    /**
     * Delete a CleanupEvent.
     * @param {CleanupEventDeleteArgs} args - Arguments to delete one CleanupEvent.
     * @example
     * // Delete one CleanupEvent
     * const CleanupEvent = await prisma.cleanupEvent.delete({
     *   where: {
     *     // ... filter to delete one CleanupEvent
     *   }
     * })
     * 
     */
    delete<T extends CleanupEventDeleteArgs>(args: SelectSubset<T, CleanupEventDeleteArgs<ExtArgs>>): Prisma__CleanupEventClient<$Result.GetResult<Prisma.$CleanupEventPayload<ExtArgs>, T, "delete", GlobalOmitOptions>, never, ExtArgs, GlobalOmitOptions>

    /**
     * Update one CleanupEvent.
     * @param {CleanupEventUpdateArgs} args - Arguments to update one CleanupEvent.
     * @example
     * // Update one CleanupEvent
     * const cleanupEvent = await prisma.cleanupEvent.update({
     *   where: {
     *     // ... provide filter here
     *   },
     *   data: {
     *     // ... provide data here
     *   }
     * })
     * 
     */
    update<T extends CleanupEventUpdateArgs>(args: SelectSubset<T, CleanupEventUpdateArgs<ExtArgs>>): Prisma__CleanupEventClient<$Result.GetResult<Prisma.$CleanupEventPayload<ExtArgs>, T, "update", GlobalOmitOptions>, never, ExtArgs, GlobalOmitOptions>

    /**
     * Delete zero or more CleanupEvents.
     * @param {CleanupEventDeleteManyArgs} args - Arguments to filter CleanupEvents to delete.
     * @example
     * // Delete a few CleanupEvents
     * const { count } = await prisma.cleanupEvent.deleteMany({
     *   where: {
     *     // ... provide filter here
     *   }
     * })
     * 
     */
    deleteMany<T extends CleanupEventDeleteManyArgs>(args?: SelectSubset<T, CleanupEventDeleteManyArgs<ExtArgs>>): Prisma.PrismaPromise<BatchPayload>

    /**
     * Update zero or more CleanupEvents.
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * @param {CleanupEventUpdateManyArgs} args - Arguments to update one or more rows.
     * @example
     * // Update many CleanupEvents
     * const cleanupEvent = await prisma.cleanupEvent.updateMany({
     *   where: {
     *     // ... provide filter here
     *   },
     *   data: {
     *     // ... provide data here
     *   }
     * })
     * 
     */
    updateMany<T extends CleanupEventUpdateManyArgs>(args: SelectSubset<T, CleanupEventUpdateManyArgs<ExtArgs>>): Prisma.PrismaPromise<BatchPayload>

    /**
     * Update zero or more CleanupEvents and returns the data updated in the database.
     * @param {CleanupEventUpdateManyAndReturnArgs} args - Arguments to update many CleanupEvents.
     * @example
     * // Update many CleanupEvents
     * const cleanupEvent = await prisma.cleanupEvent.updateManyAndReturn({
     *   where: {
     *     // ... provide filter here
     *   },
     *   data: [
     *     // ... provide data here
     *   ]
     * })
     * 
     * // Update zero or more CleanupEvents and only return the `id`
     * const cleanupEventWithIdOnly = await prisma.cleanupEvent.updateManyAndReturn({
     *   select: { id: true },
     *   where: {
     *     // ... provide filter here
     *   },
     *   data: [
     *     // ... provide data here
     *   ]
     * })
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * 
     */
    updateManyAndReturn<T extends CleanupEventUpdateManyAndReturnArgs>(args: SelectSubset<T, CleanupEventUpdateManyAndReturnArgs<ExtArgs>>): Prisma.PrismaPromise<$Result.GetResult<Prisma.$CleanupEventPayload<ExtArgs>, T, "updateManyAndReturn", GlobalOmitOptions>>

    /**
     * Create or update one CleanupEvent.
     * @param {CleanupEventUpsertArgs} args - Arguments to update or create a CleanupEvent.
     * @example
     * // Update or create a CleanupEvent
     * const cleanupEvent = await prisma.cleanupEvent.upsert({
     *   create: {
     *     // ... data to create a CleanupEvent
     *   },
     *   update: {
     *     // ... in case it already exists, update
     *   },
     *   where: {
     *     // ... the filter for the CleanupEvent we want to update
     *   }
     * })
     */
    upsert<T extends CleanupEventUpsertArgs>(args: SelectSubset<T, CleanupEventUpsertArgs<ExtArgs>>): Prisma__CleanupEventClient<$Result.GetResult<Prisma.$CleanupEventPayload<ExtArgs>, T, "upsert", GlobalOmitOptions>, never, ExtArgs, GlobalOmitOptions>


    /**
     * Count the number of CleanupEvents.
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * @param {CleanupEventCountArgs} args - Arguments to filter CleanupEvents to count.
     * @example
     * // Count the number of CleanupEvents
     * const count = await prisma.cleanupEvent.count({
     *   where: {
     *     // ... the filter for the CleanupEvents we want to count
     *   }
     * })
    **/
    count<T extends CleanupEventCountArgs>(
      args?: Subset<T, CleanupEventCountArgs>,
    ): Prisma.PrismaPromise<
      T extends $Utils.Record<'select', any>
        ? T['select'] extends true
          ? number
          : GetScalarType<T['select'], CleanupEventCountAggregateOutputType>
        : number
    >

    /**
     * Allows you to perform aggregations operations on a CleanupEvent.
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * @param {CleanupEventAggregateArgs} args - Select which aggregations you would like to apply and on what fields.
     * @example
     * // Ordered by age ascending
     * // Where email contains prisma.io
     * // Limited to the 10 users
     * const aggregations = await prisma.user.aggregate({
     *   _avg: {
     *     age: true,
     *   },
     *   where: {
     *     email: {
     *       contains: "prisma.io",
     *     },
     *   },
     *   orderBy: {
     *     age: "asc",
     *   },
     *   take: 10,
     * })
    **/
    aggregate<T extends CleanupEventAggregateArgs>(args: Subset<T, CleanupEventAggregateArgs>): Prisma.PrismaPromise<GetCleanupEventAggregateType<T>>

    /**
     * Group by CleanupEvent.
     * Note, that providing `undefined` is treated as the value not being there.
     * Read more here: https://pris.ly/d/null-undefined
     * @param {CleanupEventGroupByArgs} args - Group by arguments.
     * @example
     * // Group by city, order by createdAt, get count
     * const result = await prisma.user.groupBy({
     *   by: ['city', 'createdAt'],
     *   orderBy: {
     *     createdAt: true
     *   },
     *   _count: {
     *     _all: true
     *   },
     * })
     * 
    **/
    groupBy<
      T extends CleanupEventGroupByArgs,
      HasSelectOrTake extends Or<
        Extends<'skip', Keys<T>>,
        Extends<'take', Keys<T>>
      >,
      OrderByArg extends True extends HasSelectOrTake
        ? { orderBy: CleanupEventGroupByArgs['orderBy'] }
        : { orderBy?: CleanupEventGroupByArgs['orderBy'] },
      OrderFields extends ExcludeUnderscoreKeys<Keys<MaybeTupleToUnion<T['orderBy']>>>,
      ByFields extends MaybeTupleToUnion<T['by']>,
      ByValid extends Has<ByFields, OrderFields>,
      HavingFields extends GetHavingFields<T['having']>,
      HavingValid extends Has<ByFields, HavingFields>,
      ByEmpty extends T['by'] extends never[] ? True : False,
      InputErrors extends ByEmpty extends True
      ? `Error: "by" must not be empty.`
      : HavingValid extends False
      ? {
          [P in HavingFields]: P extends ByFields
            ? never
            : P extends string
            ? `Error: Field "${P}" used in "having" needs to be provided in "by".`
            : [
                Error,
                'Field ',
                P,
                ` in "having" needs to be provided in "by"`,
              ]
        }[HavingFields]
      : 'take' extends Keys<T>
      ? 'orderBy' extends Keys<T>
        ? ByValid extends True
          ? {}
          : {
              [P in OrderFields]: P extends ByFields
                ? never
                : `Error: Field "${P}" in "orderBy" needs to be provided in "by"`
            }[OrderFields]
        : 'Error: If you provide "take", you also need to provide "orderBy"'
      : 'skip' extends Keys<T>
      ? 'orderBy' extends Keys<T>
        ? ByValid extends True
          ? {}
          : {
              [P in OrderFields]: P extends ByFields
                ? never
                : `Error: Field "${P}" in "orderBy" needs to be provided in "by"`
            }[OrderFields]
        : 'Error: If you provide "skip", you also need to provide "orderBy"'
      : ByValid extends True
      ? {}
      : {
          [P in OrderFields]: P extends ByFields
            ? never
            : `Error: Field "${P}" in "orderBy" needs to be provided in "by"`
        }[OrderFields]
    >(args: SubsetIntersection<T, CleanupEventGroupByArgs, OrderByArg> & InputErrors): {} extends InputErrors ? GetCleanupEventGroupByPayload<T> : Prisma.PrismaPromise<InputErrors>
  /**
   * Fields of the CleanupEvent model
   */
  readonly fields: CleanupEventFieldRefs;
  }

  /**
   * The delegate class that acts as a "Promise-like" for CleanupEvent.
   * Why is this prefixed with `Prisma__`?
   * Because we want to prevent naming conflicts as mentioned in
   * https://github.com/prisma/prisma-client-js/issues/707
   */
  export interface Prisma__CleanupEventClient<T, Null = never, ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs, GlobalOmitOptions = {}> extends Prisma.PrismaPromise<T> {
    readonly [Symbol.toStringTag]: "PrismaPromise"
    site<T extends SiteDefaultArgs<ExtArgs> = {}>(args?: Subset<T, SiteDefaultArgs<ExtArgs>>): Prisma__SiteClient<$Result.GetResult<Prisma.$SitePayload<ExtArgs>, T, "findUniqueOrThrow", GlobalOmitOptions> | Null, Null, ExtArgs, GlobalOmitOptions>
    /**
     * Attaches callbacks for the resolution and/or rejection of the Promise.
     * @param onfulfilled The callback to execute when the Promise is resolved.
     * @param onrejected The callback to execute when the Promise is rejected.
     * @returns A Promise for the completion of which ever callback is executed.
     */
    then<TResult1 = T, TResult2 = never>(onfulfilled?: ((value: T) => TResult1 | PromiseLike<TResult1>) | undefined | null, onrejected?: ((reason: any) => TResult2 | PromiseLike<TResult2>) | undefined | null): $Utils.JsPromise<TResult1 | TResult2>
    /**
     * Attaches a callback for only the rejection of the Promise.
     * @param onrejected The callback to execute when the Promise is rejected.
     * @returns A Promise for the completion of the callback.
     */
    catch<TResult = never>(onrejected?: ((reason: any) => TResult | PromiseLike<TResult>) | undefined | null): $Utils.JsPromise<T | TResult>
    /**
     * Attaches a callback that is invoked when the Promise is settled (fulfilled or rejected). The
     * resolved value cannot be modified from the callback.
     * @param onfinally The callback to execute when the Promise is settled (fulfilled or rejected).
     * @returns A Promise for the completion of the callback.
     */
    finally(onfinally?: (() => void) | undefined | null): $Utils.JsPromise<T>
  }




  /**
   * Fields of the CleanupEvent model
   */
  interface CleanupEventFieldRefs {
    readonly id: FieldRef<"CleanupEvent", 'String'>
    readonly createdAt: FieldRef<"CleanupEvent", 'DateTime'>
    readonly updatedAt: FieldRef<"CleanupEvent", 'DateTime'>
    readonly siteId: FieldRef<"CleanupEvent", 'String'>
    readonly scheduledAt: FieldRef<"CleanupEvent", 'DateTime'>
    readonly completedAt: FieldRef<"CleanupEvent", 'DateTime'>
    readonly organizerId: FieldRef<"CleanupEvent", 'String'>
    readonly participantCount: FieldRef<"CleanupEvent", 'Int'>
  }
    

  // Custom InputTypes
  /**
   * CleanupEvent findUnique
   */
  export type CleanupEventFindUniqueArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the CleanupEvent
     */
    select?: CleanupEventSelect<ExtArgs> | null
    /**
     * Omit specific fields from the CleanupEvent
     */
    omit?: CleanupEventOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: CleanupEventInclude<ExtArgs> | null
    /**
     * Filter, which CleanupEvent to fetch.
     */
    where: CleanupEventWhereUniqueInput
  }

  /**
   * CleanupEvent findUniqueOrThrow
   */
  export type CleanupEventFindUniqueOrThrowArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the CleanupEvent
     */
    select?: CleanupEventSelect<ExtArgs> | null
    /**
     * Omit specific fields from the CleanupEvent
     */
    omit?: CleanupEventOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: CleanupEventInclude<ExtArgs> | null
    /**
     * Filter, which CleanupEvent to fetch.
     */
    where: CleanupEventWhereUniqueInput
  }

  /**
   * CleanupEvent findFirst
   */
  export type CleanupEventFindFirstArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the CleanupEvent
     */
    select?: CleanupEventSelect<ExtArgs> | null
    /**
     * Omit specific fields from the CleanupEvent
     */
    omit?: CleanupEventOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: CleanupEventInclude<ExtArgs> | null
    /**
     * Filter, which CleanupEvent to fetch.
     */
    where?: CleanupEventWhereInput
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/sorting Sorting Docs}
     * 
     * Determine the order of CleanupEvents to fetch.
     */
    orderBy?: CleanupEventOrderByWithRelationInput | CleanupEventOrderByWithRelationInput[]
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination#cursor-based-pagination Cursor Docs}
     * 
     * Sets the position for searching for CleanupEvents.
     */
    cursor?: CleanupEventWhereUniqueInput
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination Pagination Docs}
     * 
     * Take `±n` CleanupEvents from the position of the cursor.
     */
    take?: number
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination Pagination Docs}
     * 
     * Skip the first `n` CleanupEvents.
     */
    skip?: number
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/distinct Distinct Docs}
     * 
     * Filter by unique combinations of CleanupEvents.
     */
    distinct?: CleanupEventScalarFieldEnum | CleanupEventScalarFieldEnum[]
  }

  /**
   * CleanupEvent findFirstOrThrow
   */
  export type CleanupEventFindFirstOrThrowArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the CleanupEvent
     */
    select?: CleanupEventSelect<ExtArgs> | null
    /**
     * Omit specific fields from the CleanupEvent
     */
    omit?: CleanupEventOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: CleanupEventInclude<ExtArgs> | null
    /**
     * Filter, which CleanupEvent to fetch.
     */
    where?: CleanupEventWhereInput
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/sorting Sorting Docs}
     * 
     * Determine the order of CleanupEvents to fetch.
     */
    orderBy?: CleanupEventOrderByWithRelationInput | CleanupEventOrderByWithRelationInput[]
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination#cursor-based-pagination Cursor Docs}
     * 
     * Sets the position for searching for CleanupEvents.
     */
    cursor?: CleanupEventWhereUniqueInput
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination Pagination Docs}
     * 
     * Take `±n` CleanupEvents from the position of the cursor.
     */
    take?: number
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination Pagination Docs}
     * 
     * Skip the first `n` CleanupEvents.
     */
    skip?: number
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/distinct Distinct Docs}
     * 
     * Filter by unique combinations of CleanupEvents.
     */
    distinct?: CleanupEventScalarFieldEnum | CleanupEventScalarFieldEnum[]
  }

  /**
   * CleanupEvent findMany
   */
  export type CleanupEventFindManyArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the CleanupEvent
     */
    select?: CleanupEventSelect<ExtArgs> | null
    /**
     * Omit specific fields from the CleanupEvent
     */
    omit?: CleanupEventOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: CleanupEventInclude<ExtArgs> | null
    /**
     * Filter, which CleanupEvents to fetch.
     */
    where?: CleanupEventWhereInput
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/sorting Sorting Docs}
     * 
     * Determine the order of CleanupEvents to fetch.
     */
    orderBy?: CleanupEventOrderByWithRelationInput | CleanupEventOrderByWithRelationInput[]
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination#cursor-based-pagination Cursor Docs}
     * 
     * Sets the position for listing CleanupEvents.
     */
    cursor?: CleanupEventWhereUniqueInput
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination Pagination Docs}
     * 
     * Take `±n` CleanupEvents from the position of the cursor.
     */
    take?: number
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/pagination Pagination Docs}
     * 
     * Skip the first `n` CleanupEvents.
     */
    skip?: number
    /**
     * {@link https://www.prisma.io/docs/concepts/components/prisma-client/distinct Distinct Docs}
     * 
     * Filter by unique combinations of CleanupEvents.
     */
    distinct?: CleanupEventScalarFieldEnum | CleanupEventScalarFieldEnum[]
  }

  /**
   * CleanupEvent create
   */
  export type CleanupEventCreateArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the CleanupEvent
     */
    select?: CleanupEventSelect<ExtArgs> | null
    /**
     * Omit specific fields from the CleanupEvent
     */
    omit?: CleanupEventOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: CleanupEventInclude<ExtArgs> | null
    /**
     * The data needed to create a CleanupEvent.
     */
    data: XOR<CleanupEventCreateInput, CleanupEventUncheckedCreateInput>
  }

  /**
   * CleanupEvent createMany
   */
  export type CleanupEventCreateManyArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * The data used to create many CleanupEvents.
     */
    data: CleanupEventCreateManyInput | CleanupEventCreateManyInput[]
    skipDuplicates?: boolean
  }

  /**
   * CleanupEvent createManyAndReturn
   */
  export type CleanupEventCreateManyAndReturnArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the CleanupEvent
     */
    select?: CleanupEventSelectCreateManyAndReturn<ExtArgs> | null
    /**
     * Omit specific fields from the CleanupEvent
     */
    omit?: CleanupEventOmit<ExtArgs> | null
    /**
     * The data used to create many CleanupEvents.
     */
    data: CleanupEventCreateManyInput | CleanupEventCreateManyInput[]
    skipDuplicates?: boolean
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: CleanupEventIncludeCreateManyAndReturn<ExtArgs> | null
  }

  /**
   * CleanupEvent update
   */
  export type CleanupEventUpdateArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the CleanupEvent
     */
    select?: CleanupEventSelect<ExtArgs> | null
    /**
     * Omit specific fields from the CleanupEvent
     */
    omit?: CleanupEventOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: CleanupEventInclude<ExtArgs> | null
    /**
     * The data needed to update a CleanupEvent.
     */
    data: XOR<CleanupEventUpdateInput, CleanupEventUncheckedUpdateInput>
    /**
     * Choose, which CleanupEvent to update.
     */
    where: CleanupEventWhereUniqueInput
  }

  /**
   * CleanupEvent updateMany
   */
  export type CleanupEventUpdateManyArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * The data used to update CleanupEvents.
     */
    data: XOR<CleanupEventUpdateManyMutationInput, CleanupEventUncheckedUpdateManyInput>
    /**
     * Filter which CleanupEvents to update
     */
    where?: CleanupEventWhereInput
    /**
     * Limit how many CleanupEvents to update.
     */
    limit?: number
  }

  /**
   * CleanupEvent updateManyAndReturn
   */
  export type CleanupEventUpdateManyAndReturnArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the CleanupEvent
     */
    select?: CleanupEventSelectUpdateManyAndReturn<ExtArgs> | null
    /**
     * Omit specific fields from the CleanupEvent
     */
    omit?: CleanupEventOmit<ExtArgs> | null
    /**
     * The data used to update CleanupEvents.
     */
    data: XOR<CleanupEventUpdateManyMutationInput, CleanupEventUncheckedUpdateManyInput>
    /**
     * Filter which CleanupEvents to update
     */
    where?: CleanupEventWhereInput
    /**
     * Limit how many CleanupEvents to update.
     */
    limit?: number
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: CleanupEventIncludeUpdateManyAndReturn<ExtArgs> | null
  }

  /**
   * CleanupEvent upsert
   */
  export type CleanupEventUpsertArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the CleanupEvent
     */
    select?: CleanupEventSelect<ExtArgs> | null
    /**
     * Omit specific fields from the CleanupEvent
     */
    omit?: CleanupEventOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: CleanupEventInclude<ExtArgs> | null
    /**
     * The filter to search for the CleanupEvent to update in case it exists.
     */
    where: CleanupEventWhereUniqueInput
    /**
     * In case the CleanupEvent found by the `where` argument doesn't exist, create a new CleanupEvent with this data.
     */
    create: XOR<CleanupEventCreateInput, CleanupEventUncheckedCreateInput>
    /**
     * In case the CleanupEvent was found with the provided `where` argument, update it with this data.
     */
    update: XOR<CleanupEventUpdateInput, CleanupEventUncheckedUpdateInput>
  }

  /**
   * CleanupEvent delete
   */
  export type CleanupEventDeleteArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the CleanupEvent
     */
    select?: CleanupEventSelect<ExtArgs> | null
    /**
     * Omit specific fields from the CleanupEvent
     */
    omit?: CleanupEventOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: CleanupEventInclude<ExtArgs> | null
    /**
     * Filter which CleanupEvent to delete.
     */
    where: CleanupEventWhereUniqueInput
  }

  /**
   * CleanupEvent deleteMany
   */
  export type CleanupEventDeleteManyArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Filter which CleanupEvents to delete
     */
    where?: CleanupEventWhereInput
    /**
     * Limit how many CleanupEvents to delete.
     */
    limit?: number
  }

  /**
   * CleanupEvent without action
   */
  export type CleanupEventDefaultArgs<ExtArgs extends $Extensions.InternalArgs = $Extensions.DefaultArgs> = {
    /**
     * Select specific fields to fetch from the CleanupEvent
     */
    select?: CleanupEventSelect<ExtArgs> | null
    /**
     * Omit specific fields from the CleanupEvent
     */
    omit?: CleanupEventOmit<ExtArgs> | null
    /**
     * Choose, which related nodes to fetch as well
     */
    include?: CleanupEventInclude<ExtArgs> | null
  }


  /**
   * Enums
   */

  export const TransactionIsolationLevel: {
    ReadUncommitted: 'ReadUncommitted',
    ReadCommitted: 'ReadCommitted',
    RepeatableRead: 'RepeatableRead',
    Serializable: 'Serializable'
  };

  export type TransactionIsolationLevel = (typeof TransactionIsolationLevel)[keyof typeof TransactionIsolationLevel]


  export const UserScalarFieldEnum: {
    id: 'id',
    createdAt: 'createdAt',
    updatedAt: 'updatedAt',
    firstName: 'firstName',
    lastName: 'lastName',
    email: 'email',
    phoneNumber: 'phoneNumber',
    passwordHash: 'passwordHash',
    role: 'role',
    status: 'status',
    isPhoneVerified: 'isPhoneVerified',
    pointsBalance: 'pointsBalance',
    totalPointsEarned: 'totalPointsEarned',
    totalPointsSpent: 'totalPointsSpent',
    lastActiveAt: 'lastActiveAt'
  };

  export type UserScalarFieldEnum = (typeof UserScalarFieldEnum)[keyof typeof UserScalarFieldEnum]


  export const UserSessionScalarFieldEnum: {
    id: 'id',
    createdAt: 'createdAt',
    userId: 'userId',
    tokenId: 'tokenId',
    refreshTokenHash: 'refreshTokenHash',
    deviceInfo: 'deviceInfo',
    ipAddress: 'ipAddress',
    expiresAt: 'expiresAt',
    revokedAt: 'revokedAt'
  };

  export type UserSessionScalarFieldEnum = (typeof UserSessionScalarFieldEnum)[keyof typeof UserSessionScalarFieldEnum]


  export const PhoneOtpScalarFieldEnum: {
    id: 'id',
    createdAt: 'createdAt',
    phoneNumber: 'phoneNumber',
    code: 'code',
    expiresAt: 'expiresAt',
    attemptCount: 'attemptCount'
  };

  export type PhoneOtpScalarFieldEnum = (typeof PhoneOtpScalarFieldEnum)[keyof typeof PhoneOtpScalarFieldEnum]


  export const LoginFailureScalarFieldEnum: {
    id: 'id',
    phoneNumber: 'phoneNumber',
    firstFailedAt: 'firstFailedAt',
    attemptCount: 'attemptCount'
  };

  export type LoginFailureScalarFieldEnum = (typeof LoginFailureScalarFieldEnum)[keyof typeof LoginFailureScalarFieldEnum]


  export const AdminNotificationScalarFieldEnum: {
    id: 'id',
    createdAt: 'createdAt',
    updatedAt: 'updatedAt',
    userId: 'userId',
    title: 'title',
    message: 'message',
    timeLabel: 'timeLabel',
    tone: 'tone',
    category: 'category',
    isUnread: 'isUnread',
    href: 'href'
  };

  export type AdminNotificationScalarFieldEnum = (typeof AdminNotificationScalarFieldEnum)[keyof typeof AdminNotificationScalarFieldEnum]


  export const PointTransactionScalarFieldEnum: {
    id: 'id',
    createdAt: 'createdAt',
    userId: 'userId',
    delta: 'delta',
    balanceAfter: 'balanceAfter',
    reasonCode: 'reasonCode',
    referenceType: 'referenceType',
    referenceId: 'referenceId',
    metadata: 'metadata'
  };

  export type PointTransactionScalarFieldEnum = (typeof PointTransactionScalarFieldEnum)[keyof typeof PointTransactionScalarFieldEnum]


  export const SiteScalarFieldEnum: {
    id: 'id',
    createdAt: 'createdAt',
    updatedAt: 'updatedAt',
    latitude: 'latitude',
    longitude: 'longitude',
    description: 'description',
    status: 'status'
  };

  export type SiteScalarFieldEnum = (typeof SiteScalarFieldEnum)[keyof typeof SiteScalarFieldEnum]


  export const ReportScalarFieldEnum: {
    id: 'id',
    createdAt: 'createdAt',
    reportNumber: 'reportNumber',
    siteId: 'siteId',
    reporterId: 'reporterId',
    description: 'description',
    mediaUrls: 'mediaUrls',
    category: 'category',
    severity: 'severity',
    status: 'status',
    moderatedAt: 'moderatedAt',
    moderationReason: 'moderationReason',
    moderatedById: 'moderatedById',
    potentialDuplicateOfId: 'potentialDuplicateOfId'
  };

  export type ReportScalarFieldEnum = (typeof ReportScalarFieldEnum)[keyof typeof ReportScalarFieldEnum]


  export const ReportCoReporterScalarFieldEnum: {
    id: 'id',
    createdAt: 'createdAt',
    reportId: 'reportId',
    userId: 'userId'
  };

  export type ReportCoReporterScalarFieldEnum = (typeof ReportCoReporterScalarFieldEnum)[keyof typeof ReportCoReporterScalarFieldEnum]


  export const CleanupEventScalarFieldEnum: {
    id: 'id',
    createdAt: 'createdAt',
    updatedAt: 'updatedAt',
    siteId: 'siteId',
    scheduledAt: 'scheduledAt',
    completedAt: 'completedAt',
    organizerId: 'organizerId',
    participantCount: 'participantCount'
  };

  export type CleanupEventScalarFieldEnum = (typeof CleanupEventScalarFieldEnum)[keyof typeof CleanupEventScalarFieldEnum]


  export const SortOrder: {
    asc: 'asc',
    desc: 'desc'
  };

  export type SortOrder = (typeof SortOrder)[keyof typeof SortOrder]


  export const NullableJsonNullValueInput: {
    DbNull: typeof DbNull,
    JsonNull: typeof JsonNull
  };

  export type NullableJsonNullValueInput = (typeof NullableJsonNullValueInput)[keyof typeof NullableJsonNullValueInput]


  export const QueryMode: {
    default: 'default',
    insensitive: 'insensitive'
  };

  export type QueryMode = (typeof QueryMode)[keyof typeof QueryMode]


  export const NullsOrder: {
    first: 'first',
    last: 'last'
  };

  export type NullsOrder = (typeof NullsOrder)[keyof typeof NullsOrder]


  export const JsonNullValueFilter: {
    DbNull: typeof DbNull,
    JsonNull: typeof JsonNull,
    AnyNull: typeof AnyNull
  };

  export type JsonNullValueFilter = (typeof JsonNullValueFilter)[keyof typeof JsonNullValueFilter]


  /**
   * Field references
   */


  /**
   * Reference to a field of type 'String'
   */
  export type StringFieldRefInput<$PrismaModel> = FieldRefInputType<$PrismaModel, 'String'>
    


  /**
   * Reference to a field of type 'String[]'
   */
  export type ListStringFieldRefInput<$PrismaModel> = FieldRefInputType<$PrismaModel, 'String[]'>
    


  /**
   * Reference to a field of type 'DateTime'
   */
  export type DateTimeFieldRefInput<$PrismaModel> = FieldRefInputType<$PrismaModel, 'DateTime'>
    


  /**
   * Reference to a field of type 'DateTime[]'
   */
  export type ListDateTimeFieldRefInput<$PrismaModel> = FieldRefInputType<$PrismaModel, 'DateTime[]'>
    


  /**
   * Reference to a field of type 'Role'
   */
  export type EnumRoleFieldRefInput<$PrismaModel> = FieldRefInputType<$PrismaModel, 'Role'>
    


  /**
   * Reference to a field of type 'Role[]'
   */
  export type ListEnumRoleFieldRefInput<$PrismaModel> = FieldRefInputType<$PrismaModel, 'Role[]'>
    


  /**
   * Reference to a field of type 'UserStatus'
   */
  export type EnumUserStatusFieldRefInput<$PrismaModel> = FieldRefInputType<$PrismaModel, 'UserStatus'>
    


  /**
   * Reference to a field of type 'UserStatus[]'
   */
  export type ListEnumUserStatusFieldRefInput<$PrismaModel> = FieldRefInputType<$PrismaModel, 'UserStatus[]'>
    


  /**
   * Reference to a field of type 'Boolean'
   */
  export type BooleanFieldRefInput<$PrismaModel> = FieldRefInputType<$PrismaModel, 'Boolean'>
    


  /**
   * Reference to a field of type 'Int'
   */
  export type IntFieldRefInput<$PrismaModel> = FieldRefInputType<$PrismaModel, 'Int'>
    


  /**
   * Reference to a field of type 'Int[]'
   */
  export type ListIntFieldRefInput<$PrismaModel> = FieldRefInputType<$PrismaModel, 'Int[]'>
    


  /**
   * Reference to a field of type 'AdminNotificationTone'
   */
  export type EnumAdminNotificationToneFieldRefInput<$PrismaModel> = FieldRefInputType<$PrismaModel, 'AdminNotificationTone'>
    


  /**
   * Reference to a field of type 'AdminNotificationTone[]'
   */
  export type ListEnumAdminNotificationToneFieldRefInput<$PrismaModel> = FieldRefInputType<$PrismaModel, 'AdminNotificationTone[]'>
    


  /**
   * Reference to a field of type 'AdminNotificationCategory'
   */
  export type EnumAdminNotificationCategoryFieldRefInput<$PrismaModel> = FieldRefInputType<$PrismaModel, 'AdminNotificationCategory'>
    


  /**
   * Reference to a field of type 'AdminNotificationCategory[]'
   */
  export type ListEnumAdminNotificationCategoryFieldRefInput<$PrismaModel> = FieldRefInputType<$PrismaModel, 'AdminNotificationCategory[]'>
    


  /**
   * Reference to a field of type 'Json'
   */
  export type JsonFieldRefInput<$PrismaModel> = FieldRefInputType<$PrismaModel, 'Json'>
    


  /**
   * Reference to a field of type 'QueryMode'
   */
  export type EnumQueryModeFieldRefInput<$PrismaModel> = FieldRefInputType<$PrismaModel, 'QueryMode'>
    


  /**
   * Reference to a field of type 'Float'
   */
  export type FloatFieldRefInput<$PrismaModel> = FieldRefInputType<$PrismaModel, 'Float'>
    


  /**
   * Reference to a field of type 'Float[]'
   */
  export type ListFloatFieldRefInput<$PrismaModel> = FieldRefInputType<$PrismaModel, 'Float[]'>
    


  /**
   * Reference to a field of type 'SiteStatus'
   */
  export type EnumSiteStatusFieldRefInput<$PrismaModel> = FieldRefInputType<$PrismaModel, 'SiteStatus'>
    


  /**
   * Reference to a field of type 'SiteStatus[]'
   */
  export type ListEnumSiteStatusFieldRefInput<$PrismaModel> = FieldRefInputType<$PrismaModel, 'SiteStatus[]'>
    


  /**
   * Reference to a field of type 'ReportStatus'
   */
  export type EnumReportStatusFieldRefInput<$PrismaModel> = FieldRefInputType<$PrismaModel, 'ReportStatus'>
    


  /**
   * Reference to a field of type 'ReportStatus[]'
   */
  export type ListEnumReportStatusFieldRefInput<$PrismaModel> = FieldRefInputType<$PrismaModel, 'ReportStatus[]'>
    
  /**
   * Deep Input Types
   */


  export type UserWhereInput = {
    AND?: UserWhereInput | UserWhereInput[]
    OR?: UserWhereInput[]
    NOT?: UserWhereInput | UserWhereInput[]
    id?: StringFilter<"User"> | string
    createdAt?: DateTimeFilter<"User"> | Date | string
    updatedAt?: DateTimeFilter<"User"> | Date | string
    firstName?: StringFilter<"User"> | string
    lastName?: StringFilter<"User"> | string
    email?: StringFilter<"User"> | string
    phoneNumber?: StringFilter<"User"> | string
    passwordHash?: StringFilter<"User"> | string
    role?: EnumRoleFilter<"User"> | $Enums.Role
    status?: EnumUserStatusFilter<"User"> | $Enums.UserStatus
    isPhoneVerified?: BoolFilter<"User"> | boolean
    pointsBalance?: IntFilter<"User"> | number
    totalPointsEarned?: IntFilter<"User"> | number
    totalPointsSpent?: IntFilter<"User"> | number
    lastActiveAt?: DateTimeNullableFilter<"User"> | Date | string | null
    reports?: ReportListRelationFilter
    moderatedReports?: ReportListRelationFilter
    adminNotifications?: AdminNotificationListRelationFilter
    pointTransactions?: PointTransactionListRelationFilter
    coReportedReports?: ReportCoReporterListRelationFilter
    sessions?: UserSessionListRelationFilter
  }

  export type UserOrderByWithRelationInput = {
    id?: SortOrder
    createdAt?: SortOrder
    updatedAt?: SortOrder
    firstName?: SortOrder
    lastName?: SortOrder
    email?: SortOrder
    phoneNumber?: SortOrder
    passwordHash?: SortOrder
    role?: SortOrder
    status?: SortOrder
    isPhoneVerified?: SortOrder
    pointsBalance?: SortOrder
    totalPointsEarned?: SortOrder
    totalPointsSpent?: SortOrder
    lastActiveAt?: SortOrderInput | SortOrder
    reports?: ReportOrderByRelationAggregateInput
    moderatedReports?: ReportOrderByRelationAggregateInput
    adminNotifications?: AdminNotificationOrderByRelationAggregateInput
    pointTransactions?: PointTransactionOrderByRelationAggregateInput
    coReportedReports?: ReportCoReporterOrderByRelationAggregateInput
    sessions?: UserSessionOrderByRelationAggregateInput
  }

  export type UserWhereUniqueInput = Prisma.AtLeast<{
    id?: string
    email?: string
    phoneNumber?: string
    AND?: UserWhereInput | UserWhereInput[]
    OR?: UserWhereInput[]
    NOT?: UserWhereInput | UserWhereInput[]
    createdAt?: DateTimeFilter<"User"> | Date | string
    updatedAt?: DateTimeFilter<"User"> | Date | string
    firstName?: StringFilter<"User"> | string
    lastName?: StringFilter<"User"> | string
    passwordHash?: StringFilter<"User"> | string
    role?: EnumRoleFilter<"User"> | $Enums.Role
    status?: EnumUserStatusFilter<"User"> | $Enums.UserStatus
    isPhoneVerified?: BoolFilter<"User"> | boolean
    pointsBalance?: IntFilter<"User"> | number
    totalPointsEarned?: IntFilter<"User"> | number
    totalPointsSpent?: IntFilter<"User"> | number
    lastActiveAt?: DateTimeNullableFilter<"User"> | Date | string | null
    reports?: ReportListRelationFilter
    moderatedReports?: ReportListRelationFilter
    adminNotifications?: AdminNotificationListRelationFilter
    pointTransactions?: PointTransactionListRelationFilter
    coReportedReports?: ReportCoReporterListRelationFilter
    sessions?: UserSessionListRelationFilter
  }, "id" | "email" | "phoneNumber">

  export type UserOrderByWithAggregationInput = {
    id?: SortOrder
    createdAt?: SortOrder
    updatedAt?: SortOrder
    firstName?: SortOrder
    lastName?: SortOrder
    email?: SortOrder
    phoneNumber?: SortOrder
    passwordHash?: SortOrder
    role?: SortOrder
    status?: SortOrder
    isPhoneVerified?: SortOrder
    pointsBalance?: SortOrder
    totalPointsEarned?: SortOrder
    totalPointsSpent?: SortOrder
    lastActiveAt?: SortOrderInput | SortOrder
    _count?: UserCountOrderByAggregateInput
    _avg?: UserAvgOrderByAggregateInput
    _max?: UserMaxOrderByAggregateInput
    _min?: UserMinOrderByAggregateInput
    _sum?: UserSumOrderByAggregateInput
  }

  export type UserScalarWhereWithAggregatesInput = {
    AND?: UserScalarWhereWithAggregatesInput | UserScalarWhereWithAggregatesInput[]
    OR?: UserScalarWhereWithAggregatesInput[]
    NOT?: UserScalarWhereWithAggregatesInput | UserScalarWhereWithAggregatesInput[]
    id?: StringWithAggregatesFilter<"User"> | string
    createdAt?: DateTimeWithAggregatesFilter<"User"> | Date | string
    updatedAt?: DateTimeWithAggregatesFilter<"User"> | Date | string
    firstName?: StringWithAggregatesFilter<"User"> | string
    lastName?: StringWithAggregatesFilter<"User"> | string
    email?: StringWithAggregatesFilter<"User"> | string
    phoneNumber?: StringWithAggregatesFilter<"User"> | string
    passwordHash?: StringWithAggregatesFilter<"User"> | string
    role?: EnumRoleWithAggregatesFilter<"User"> | $Enums.Role
    status?: EnumUserStatusWithAggregatesFilter<"User"> | $Enums.UserStatus
    isPhoneVerified?: BoolWithAggregatesFilter<"User"> | boolean
    pointsBalance?: IntWithAggregatesFilter<"User"> | number
    totalPointsEarned?: IntWithAggregatesFilter<"User"> | number
    totalPointsSpent?: IntWithAggregatesFilter<"User"> | number
    lastActiveAt?: DateTimeNullableWithAggregatesFilter<"User"> | Date | string | null
  }

  export type UserSessionWhereInput = {
    AND?: UserSessionWhereInput | UserSessionWhereInput[]
    OR?: UserSessionWhereInput[]
    NOT?: UserSessionWhereInput | UserSessionWhereInput[]
    id?: StringFilter<"UserSession"> | string
    createdAt?: DateTimeFilter<"UserSession"> | Date | string
    userId?: StringFilter<"UserSession"> | string
    tokenId?: StringFilter<"UserSession"> | string
    refreshTokenHash?: StringFilter<"UserSession"> | string
    deviceInfo?: StringNullableFilter<"UserSession"> | string | null
    ipAddress?: StringNullableFilter<"UserSession"> | string | null
    expiresAt?: DateTimeFilter<"UserSession"> | Date | string
    revokedAt?: DateTimeNullableFilter<"UserSession"> | Date | string | null
    user?: XOR<UserScalarRelationFilter, UserWhereInput>
  }

  export type UserSessionOrderByWithRelationInput = {
    id?: SortOrder
    createdAt?: SortOrder
    userId?: SortOrder
    tokenId?: SortOrder
    refreshTokenHash?: SortOrder
    deviceInfo?: SortOrderInput | SortOrder
    ipAddress?: SortOrderInput | SortOrder
    expiresAt?: SortOrder
    revokedAt?: SortOrderInput | SortOrder
    user?: UserOrderByWithRelationInput
  }

  export type UserSessionWhereUniqueInput = Prisma.AtLeast<{
    id?: string
    tokenId?: string
    AND?: UserSessionWhereInput | UserSessionWhereInput[]
    OR?: UserSessionWhereInput[]
    NOT?: UserSessionWhereInput | UserSessionWhereInput[]
    createdAt?: DateTimeFilter<"UserSession"> | Date | string
    userId?: StringFilter<"UserSession"> | string
    refreshTokenHash?: StringFilter<"UserSession"> | string
    deviceInfo?: StringNullableFilter<"UserSession"> | string | null
    ipAddress?: StringNullableFilter<"UserSession"> | string | null
    expiresAt?: DateTimeFilter<"UserSession"> | Date | string
    revokedAt?: DateTimeNullableFilter<"UserSession"> | Date | string | null
    user?: XOR<UserScalarRelationFilter, UserWhereInput>
  }, "id" | "tokenId">

  export type UserSessionOrderByWithAggregationInput = {
    id?: SortOrder
    createdAt?: SortOrder
    userId?: SortOrder
    tokenId?: SortOrder
    refreshTokenHash?: SortOrder
    deviceInfo?: SortOrderInput | SortOrder
    ipAddress?: SortOrderInput | SortOrder
    expiresAt?: SortOrder
    revokedAt?: SortOrderInput | SortOrder
    _count?: UserSessionCountOrderByAggregateInput
    _max?: UserSessionMaxOrderByAggregateInput
    _min?: UserSessionMinOrderByAggregateInput
  }

  export type UserSessionScalarWhereWithAggregatesInput = {
    AND?: UserSessionScalarWhereWithAggregatesInput | UserSessionScalarWhereWithAggregatesInput[]
    OR?: UserSessionScalarWhereWithAggregatesInput[]
    NOT?: UserSessionScalarWhereWithAggregatesInput | UserSessionScalarWhereWithAggregatesInput[]
    id?: StringWithAggregatesFilter<"UserSession"> | string
    createdAt?: DateTimeWithAggregatesFilter<"UserSession"> | Date | string
    userId?: StringWithAggregatesFilter<"UserSession"> | string
    tokenId?: StringWithAggregatesFilter<"UserSession"> | string
    refreshTokenHash?: StringWithAggregatesFilter<"UserSession"> | string
    deviceInfo?: StringNullableWithAggregatesFilter<"UserSession"> | string | null
    ipAddress?: StringNullableWithAggregatesFilter<"UserSession"> | string | null
    expiresAt?: DateTimeWithAggregatesFilter<"UserSession"> | Date | string
    revokedAt?: DateTimeNullableWithAggregatesFilter<"UserSession"> | Date | string | null
  }

  export type PhoneOtpWhereInput = {
    AND?: PhoneOtpWhereInput | PhoneOtpWhereInput[]
    OR?: PhoneOtpWhereInput[]
    NOT?: PhoneOtpWhereInput | PhoneOtpWhereInput[]
    id?: StringFilter<"PhoneOtp"> | string
    createdAt?: DateTimeFilter<"PhoneOtp"> | Date | string
    phoneNumber?: StringFilter<"PhoneOtp"> | string
    code?: StringFilter<"PhoneOtp"> | string
    expiresAt?: DateTimeFilter<"PhoneOtp"> | Date | string
    attemptCount?: IntFilter<"PhoneOtp"> | number
  }

  export type PhoneOtpOrderByWithRelationInput = {
    id?: SortOrder
    createdAt?: SortOrder
    phoneNumber?: SortOrder
    code?: SortOrder
    expiresAt?: SortOrder
    attemptCount?: SortOrder
  }

  export type PhoneOtpWhereUniqueInput = Prisma.AtLeast<{
    id?: string
    phoneNumber?: string
    AND?: PhoneOtpWhereInput | PhoneOtpWhereInput[]
    OR?: PhoneOtpWhereInput[]
    NOT?: PhoneOtpWhereInput | PhoneOtpWhereInput[]
    createdAt?: DateTimeFilter<"PhoneOtp"> | Date | string
    code?: StringFilter<"PhoneOtp"> | string
    expiresAt?: DateTimeFilter<"PhoneOtp"> | Date | string
    attemptCount?: IntFilter<"PhoneOtp"> | number
  }, "id" | "phoneNumber">

  export type PhoneOtpOrderByWithAggregationInput = {
    id?: SortOrder
    createdAt?: SortOrder
    phoneNumber?: SortOrder
    code?: SortOrder
    expiresAt?: SortOrder
    attemptCount?: SortOrder
    _count?: PhoneOtpCountOrderByAggregateInput
    _avg?: PhoneOtpAvgOrderByAggregateInput
    _max?: PhoneOtpMaxOrderByAggregateInput
    _min?: PhoneOtpMinOrderByAggregateInput
    _sum?: PhoneOtpSumOrderByAggregateInput
  }

  export type PhoneOtpScalarWhereWithAggregatesInput = {
    AND?: PhoneOtpScalarWhereWithAggregatesInput | PhoneOtpScalarWhereWithAggregatesInput[]
    OR?: PhoneOtpScalarWhereWithAggregatesInput[]
    NOT?: PhoneOtpScalarWhereWithAggregatesInput | PhoneOtpScalarWhereWithAggregatesInput[]
    id?: StringWithAggregatesFilter<"PhoneOtp"> | string
    createdAt?: DateTimeWithAggregatesFilter<"PhoneOtp"> | Date | string
    phoneNumber?: StringWithAggregatesFilter<"PhoneOtp"> | string
    code?: StringWithAggregatesFilter<"PhoneOtp"> | string
    expiresAt?: DateTimeWithAggregatesFilter<"PhoneOtp"> | Date | string
    attemptCount?: IntWithAggregatesFilter<"PhoneOtp"> | number
  }

  export type LoginFailureWhereInput = {
    AND?: LoginFailureWhereInput | LoginFailureWhereInput[]
    OR?: LoginFailureWhereInput[]
    NOT?: LoginFailureWhereInput | LoginFailureWhereInput[]
    id?: StringFilter<"LoginFailure"> | string
    phoneNumber?: StringFilter<"LoginFailure"> | string
    firstFailedAt?: DateTimeFilter<"LoginFailure"> | Date | string
    attemptCount?: IntFilter<"LoginFailure"> | number
  }

  export type LoginFailureOrderByWithRelationInput = {
    id?: SortOrder
    phoneNumber?: SortOrder
    firstFailedAt?: SortOrder
    attemptCount?: SortOrder
  }

  export type LoginFailureWhereUniqueInput = Prisma.AtLeast<{
    id?: string
    phoneNumber?: string
    AND?: LoginFailureWhereInput | LoginFailureWhereInput[]
    OR?: LoginFailureWhereInput[]
    NOT?: LoginFailureWhereInput | LoginFailureWhereInput[]
    firstFailedAt?: DateTimeFilter<"LoginFailure"> | Date | string
    attemptCount?: IntFilter<"LoginFailure"> | number
  }, "id" | "phoneNumber">

  export type LoginFailureOrderByWithAggregationInput = {
    id?: SortOrder
    phoneNumber?: SortOrder
    firstFailedAt?: SortOrder
    attemptCount?: SortOrder
    _count?: LoginFailureCountOrderByAggregateInput
    _avg?: LoginFailureAvgOrderByAggregateInput
    _max?: LoginFailureMaxOrderByAggregateInput
    _min?: LoginFailureMinOrderByAggregateInput
    _sum?: LoginFailureSumOrderByAggregateInput
  }

  export type LoginFailureScalarWhereWithAggregatesInput = {
    AND?: LoginFailureScalarWhereWithAggregatesInput | LoginFailureScalarWhereWithAggregatesInput[]
    OR?: LoginFailureScalarWhereWithAggregatesInput[]
    NOT?: LoginFailureScalarWhereWithAggregatesInput | LoginFailureScalarWhereWithAggregatesInput[]
    id?: StringWithAggregatesFilter<"LoginFailure"> | string
    phoneNumber?: StringWithAggregatesFilter<"LoginFailure"> | string
    firstFailedAt?: DateTimeWithAggregatesFilter<"LoginFailure"> | Date | string
    attemptCount?: IntWithAggregatesFilter<"LoginFailure"> | number
  }

  export type AdminNotificationWhereInput = {
    AND?: AdminNotificationWhereInput | AdminNotificationWhereInput[]
    OR?: AdminNotificationWhereInput[]
    NOT?: AdminNotificationWhereInput | AdminNotificationWhereInput[]
    id?: StringFilter<"AdminNotification"> | string
    createdAt?: DateTimeFilter<"AdminNotification"> | Date | string
    updatedAt?: DateTimeFilter<"AdminNotification"> | Date | string
    userId?: StringNullableFilter<"AdminNotification"> | string | null
    title?: StringFilter<"AdminNotification"> | string
    message?: StringFilter<"AdminNotification"> | string
    timeLabel?: StringFilter<"AdminNotification"> | string
    tone?: EnumAdminNotificationToneFilter<"AdminNotification"> | $Enums.AdminNotificationTone
    category?: EnumAdminNotificationCategoryFilter<"AdminNotification"> | $Enums.AdminNotificationCategory
    isUnread?: BoolFilter<"AdminNotification"> | boolean
    href?: StringNullableFilter<"AdminNotification"> | string | null
    user?: XOR<UserNullableScalarRelationFilter, UserWhereInput> | null
  }

  export type AdminNotificationOrderByWithRelationInput = {
    id?: SortOrder
    createdAt?: SortOrder
    updatedAt?: SortOrder
    userId?: SortOrderInput | SortOrder
    title?: SortOrder
    message?: SortOrder
    timeLabel?: SortOrder
    tone?: SortOrder
    category?: SortOrder
    isUnread?: SortOrder
    href?: SortOrderInput | SortOrder
    user?: UserOrderByWithRelationInput
  }

  export type AdminNotificationWhereUniqueInput = Prisma.AtLeast<{
    id?: string
    AND?: AdminNotificationWhereInput | AdminNotificationWhereInput[]
    OR?: AdminNotificationWhereInput[]
    NOT?: AdminNotificationWhereInput | AdminNotificationWhereInput[]
    createdAt?: DateTimeFilter<"AdminNotification"> | Date | string
    updatedAt?: DateTimeFilter<"AdminNotification"> | Date | string
    userId?: StringNullableFilter<"AdminNotification"> | string | null
    title?: StringFilter<"AdminNotification"> | string
    message?: StringFilter<"AdminNotification"> | string
    timeLabel?: StringFilter<"AdminNotification"> | string
    tone?: EnumAdminNotificationToneFilter<"AdminNotification"> | $Enums.AdminNotificationTone
    category?: EnumAdminNotificationCategoryFilter<"AdminNotification"> | $Enums.AdminNotificationCategory
    isUnread?: BoolFilter<"AdminNotification"> | boolean
    href?: StringNullableFilter<"AdminNotification"> | string | null
    user?: XOR<UserNullableScalarRelationFilter, UserWhereInput> | null
  }, "id">

  export type AdminNotificationOrderByWithAggregationInput = {
    id?: SortOrder
    createdAt?: SortOrder
    updatedAt?: SortOrder
    userId?: SortOrderInput | SortOrder
    title?: SortOrder
    message?: SortOrder
    timeLabel?: SortOrder
    tone?: SortOrder
    category?: SortOrder
    isUnread?: SortOrder
    href?: SortOrderInput | SortOrder
    _count?: AdminNotificationCountOrderByAggregateInput
    _max?: AdminNotificationMaxOrderByAggregateInput
    _min?: AdminNotificationMinOrderByAggregateInput
  }

  export type AdminNotificationScalarWhereWithAggregatesInput = {
    AND?: AdminNotificationScalarWhereWithAggregatesInput | AdminNotificationScalarWhereWithAggregatesInput[]
    OR?: AdminNotificationScalarWhereWithAggregatesInput[]
    NOT?: AdminNotificationScalarWhereWithAggregatesInput | AdminNotificationScalarWhereWithAggregatesInput[]
    id?: StringWithAggregatesFilter<"AdminNotification"> | string
    createdAt?: DateTimeWithAggregatesFilter<"AdminNotification"> | Date | string
    updatedAt?: DateTimeWithAggregatesFilter<"AdminNotification"> | Date | string
    userId?: StringNullableWithAggregatesFilter<"AdminNotification"> | string | null
    title?: StringWithAggregatesFilter<"AdminNotification"> | string
    message?: StringWithAggregatesFilter<"AdminNotification"> | string
    timeLabel?: StringWithAggregatesFilter<"AdminNotification"> | string
    tone?: EnumAdminNotificationToneWithAggregatesFilter<"AdminNotification"> | $Enums.AdminNotificationTone
    category?: EnumAdminNotificationCategoryWithAggregatesFilter<"AdminNotification"> | $Enums.AdminNotificationCategory
    isUnread?: BoolWithAggregatesFilter<"AdminNotification"> | boolean
    href?: StringNullableWithAggregatesFilter<"AdminNotification"> | string | null
  }

  export type PointTransactionWhereInput = {
    AND?: PointTransactionWhereInput | PointTransactionWhereInput[]
    OR?: PointTransactionWhereInput[]
    NOT?: PointTransactionWhereInput | PointTransactionWhereInput[]
    id?: StringFilter<"PointTransaction"> | string
    createdAt?: DateTimeFilter<"PointTransaction"> | Date | string
    userId?: StringFilter<"PointTransaction"> | string
    delta?: IntFilter<"PointTransaction"> | number
    balanceAfter?: IntFilter<"PointTransaction"> | number
    reasonCode?: StringFilter<"PointTransaction"> | string
    referenceType?: StringNullableFilter<"PointTransaction"> | string | null
    referenceId?: StringNullableFilter<"PointTransaction"> | string | null
    metadata?: JsonNullableFilter<"PointTransaction">
    user?: XOR<UserScalarRelationFilter, UserWhereInput>
  }

  export type PointTransactionOrderByWithRelationInput = {
    id?: SortOrder
    createdAt?: SortOrder
    userId?: SortOrder
    delta?: SortOrder
    balanceAfter?: SortOrder
    reasonCode?: SortOrder
    referenceType?: SortOrderInput | SortOrder
    referenceId?: SortOrderInput | SortOrder
    metadata?: SortOrderInput | SortOrder
    user?: UserOrderByWithRelationInput
  }

  export type PointTransactionWhereUniqueInput = Prisma.AtLeast<{
    id?: string
    AND?: PointTransactionWhereInput | PointTransactionWhereInput[]
    OR?: PointTransactionWhereInput[]
    NOT?: PointTransactionWhereInput | PointTransactionWhereInput[]
    createdAt?: DateTimeFilter<"PointTransaction"> | Date | string
    userId?: StringFilter<"PointTransaction"> | string
    delta?: IntFilter<"PointTransaction"> | number
    balanceAfter?: IntFilter<"PointTransaction"> | number
    reasonCode?: StringFilter<"PointTransaction"> | string
    referenceType?: StringNullableFilter<"PointTransaction"> | string | null
    referenceId?: StringNullableFilter<"PointTransaction"> | string | null
    metadata?: JsonNullableFilter<"PointTransaction">
    user?: XOR<UserScalarRelationFilter, UserWhereInput>
  }, "id">

  export type PointTransactionOrderByWithAggregationInput = {
    id?: SortOrder
    createdAt?: SortOrder
    userId?: SortOrder
    delta?: SortOrder
    balanceAfter?: SortOrder
    reasonCode?: SortOrder
    referenceType?: SortOrderInput | SortOrder
    referenceId?: SortOrderInput | SortOrder
    metadata?: SortOrderInput | SortOrder
    _count?: PointTransactionCountOrderByAggregateInput
    _avg?: PointTransactionAvgOrderByAggregateInput
    _max?: PointTransactionMaxOrderByAggregateInput
    _min?: PointTransactionMinOrderByAggregateInput
    _sum?: PointTransactionSumOrderByAggregateInput
  }

  export type PointTransactionScalarWhereWithAggregatesInput = {
    AND?: PointTransactionScalarWhereWithAggregatesInput | PointTransactionScalarWhereWithAggregatesInput[]
    OR?: PointTransactionScalarWhereWithAggregatesInput[]
    NOT?: PointTransactionScalarWhereWithAggregatesInput | PointTransactionScalarWhereWithAggregatesInput[]
    id?: StringWithAggregatesFilter<"PointTransaction"> | string
    createdAt?: DateTimeWithAggregatesFilter<"PointTransaction"> | Date | string
    userId?: StringWithAggregatesFilter<"PointTransaction"> | string
    delta?: IntWithAggregatesFilter<"PointTransaction"> | number
    balanceAfter?: IntWithAggregatesFilter<"PointTransaction"> | number
    reasonCode?: StringWithAggregatesFilter<"PointTransaction"> | string
    referenceType?: StringNullableWithAggregatesFilter<"PointTransaction"> | string | null
    referenceId?: StringNullableWithAggregatesFilter<"PointTransaction"> | string | null
    metadata?: JsonNullableWithAggregatesFilter<"PointTransaction">
  }

  export type SiteWhereInput = {
    AND?: SiteWhereInput | SiteWhereInput[]
    OR?: SiteWhereInput[]
    NOT?: SiteWhereInput | SiteWhereInput[]
    id?: StringFilter<"Site"> | string
    createdAt?: DateTimeFilter<"Site"> | Date | string
    updatedAt?: DateTimeFilter<"Site"> | Date | string
    latitude?: FloatFilter<"Site"> | number
    longitude?: FloatFilter<"Site"> | number
    description?: StringNullableFilter<"Site"> | string | null
    status?: EnumSiteStatusFilter<"Site"> | $Enums.SiteStatus
    reports?: ReportListRelationFilter
    events?: CleanupEventListRelationFilter
  }

  export type SiteOrderByWithRelationInput = {
    id?: SortOrder
    createdAt?: SortOrder
    updatedAt?: SortOrder
    latitude?: SortOrder
    longitude?: SortOrder
    description?: SortOrderInput | SortOrder
    status?: SortOrder
    reports?: ReportOrderByRelationAggregateInput
    events?: CleanupEventOrderByRelationAggregateInput
  }

  export type SiteWhereUniqueInput = Prisma.AtLeast<{
    id?: string
    AND?: SiteWhereInput | SiteWhereInput[]
    OR?: SiteWhereInput[]
    NOT?: SiteWhereInput | SiteWhereInput[]
    createdAt?: DateTimeFilter<"Site"> | Date | string
    updatedAt?: DateTimeFilter<"Site"> | Date | string
    latitude?: FloatFilter<"Site"> | number
    longitude?: FloatFilter<"Site"> | number
    description?: StringNullableFilter<"Site"> | string | null
    status?: EnumSiteStatusFilter<"Site"> | $Enums.SiteStatus
    reports?: ReportListRelationFilter
    events?: CleanupEventListRelationFilter
  }, "id">

  export type SiteOrderByWithAggregationInput = {
    id?: SortOrder
    createdAt?: SortOrder
    updatedAt?: SortOrder
    latitude?: SortOrder
    longitude?: SortOrder
    description?: SortOrderInput | SortOrder
    status?: SortOrder
    _count?: SiteCountOrderByAggregateInput
    _avg?: SiteAvgOrderByAggregateInput
    _max?: SiteMaxOrderByAggregateInput
    _min?: SiteMinOrderByAggregateInput
    _sum?: SiteSumOrderByAggregateInput
  }

  export type SiteScalarWhereWithAggregatesInput = {
    AND?: SiteScalarWhereWithAggregatesInput | SiteScalarWhereWithAggregatesInput[]
    OR?: SiteScalarWhereWithAggregatesInput[]
    NOT?: SiteScalarWhereWithAggregatesInput | SiteScalarWhereWithAggregatesInput[]
    id?: StringWithAggregatesFilter<"Site"> | string
    createdAt?: DateTimeWithAggregatesFilter<"Site"> | Date | string
    updatedAt?: DateTimeWithAggregatesFilter<"Site"> | Date | string
    latitude?: FloatWithAggregatesFilter<"Site"> | number
    longitude?: FloatWithAggregatesFilter<"Site"> | number
    description?: StringNullableWithAggregatesFilter<"Site"> | string | null
    status?: EnumSiteStatusWithAggregatesFilter<"Site"> | $Enums.SiteStatus
  }

  export type ReportWhereInput = {
    AND?: ReportWhereInput | ReportWhereInput[]
    OR?: ReportWhereInput[]
    NOT?: ReportWhereInput | ReportWhereInput[]
    id?: StringFilter<"Report"> | string
    createdAt?: DateTimeFilter<"Report"> | Date | string
    reportNumber?: StringNullableFilter<"Report"> | string | null
    siteId?: StringFilter<"Report"> | string
    reporterId?: StringNullableFilter<"Report"> | string | null
    description?: StringNullableFilter<"Report"> | string | null
    mediaUrls?: StringNullableListFilter<"Report">
    category?: StringNullableFilter<"Report"> | string | null
    severity?: IntNullableFilter<"Report"> | number | null
    status?: EnumReportStatusFilter<"Report"> | $Enums.ReportStatus
    moderatedAt?: DateTimeNullableFilter<"Report"> | Date | string | null
    moderationReason?: StringNullableFilter<"Report"> | string | null
    moderatedById?: StringNullableFilter<"Report"> | string | null
    potentialDuplicateOfId?: StringNullableFilter<"Report"> | string | null
    site?: XOR<SiteScalarRelationFilter, SiteWhereInput>
    reporter?: XOR<UserNullableScalarRelationFilter, UserWhereInput> | null
    moderatedBy?: XOR<UserNullableScalarRelationFilter, UserWhereInput> | null
    potentialDuplicateOf?: XOR<ReportNullableScalarRelationFilter, ReportWhereInput> | null
    potentialDuplicates?: ReportListRelationFilter
    coReporters?: ReportCoReporterListRelationFilter
  }

  export type ReportOrderByWithRelationInput = {
    id?: SortOrder
    createdAt?: SortOrder
    reportNumber?: SortOrderInput | SortOrder
    siteId?: SortOrder
    reporterId?: SortOrderInput | SortOrder
    description?: SortOrderInput | SortOrder
    mediaUrls?: SortOrder
    category?: SortOrderInput | SortOrder
    severity?: SortOrderInput | SortOrder
    status?: SortOrder
    moderatedAt?: SortOrderInput | SortOrder
    moderationReason?: SortOrderInput | SortOrder
    moderatedById?: SortOrderInput | SortOrder
    potentialDuplicateOfId?: SortOrderInput | SortOrder
    site?: SiteOrderByWithRelationInput
    reporter?: UserOrderByWithRelationInput
    moderatedBy?: UserOrderByWithRelationInput
    potentialDuplicateOf?: ReportOrderByWithRelationInput
    potentialDuplicates?: ReportOrderByRelationAggregateInput
    coReporters?: ReportCoReporterOrderByRelationAggregateInput
  }

  export type ReportWhereUniqueInput = Prisma.AtLeast<{
    id?: string
    reportNumber?: string
    AND?: ReportWhereInput | ReportWhereInput[]
    OR?: ReportWhereInput[]
    NOT?: ReportWhereInput | ReportWhereInput[]
    createdAt?: DateTimeFilter<"Report"> | Date | string
    siteId?: StringFilter<"Report"> | string
    reporterId?: StringNullableFilter<"Report"> | string | null
    description?: StringNullableFilter<"Report"> | string | null
    mediaUrls?: StringNullableListFilter<"Report">
    category?: StringNullableFilter<"Report"> | string | null
    severity?: IntNullableFilter<"Report"> | number | null
    status?: EnumReportStatusFilter<"Report"> | $Enums.ReportStatus
    moderatedAt?: DateTimeNullableFilter<"Report"> | Date | string | null
    moderationReason?: StringNullableFilter<"Report"> | string | null
    moderatedById?: StringNullableFilter<"Report"> | string | null
    potentialDuplicateOfId?: StringNullableFilter<"Report"> | string | null
    site?: XOR<SiteScalarRelationFilter, SiteWhereInput>
    reporter?: XOR<UserNullableScalarRelationFilter, UserWhereInput> | null
    moderatedBy?: XOR<UserNullableScalarRelationFilter, UserWhereInput> | null
    potentialDuplicateOf?: XOR<ReportNullableScalarRelationFilter, ReportWhereInput> | null
    potentialDuplicates?: ReportListRelationFilter
    coReporters?: ReportCoReporterListRelationFilter
  }, "id" | "reportNumber">

  export type ReportOrderByWithAggregationInput = {
    id?: SortOrder
    createdAt?: SortOrder
    reportNumber?: SortOrderInput | SortOrder
    siteId?: SortOrder
    reporterId?: SortOrderInput | SortOrder
    description?: SortOrderInput | SortOrder
    mediaUrls?: SortOrder
    category?: SortOrderInput | SortOrder
    severity?: SortOrderInput | SortOrder
    status?: SortOrder
    moderatedAt?: SortOrderInput | SortOrder
    moderationReason?: SortOrderInput | SortOrder
    moderatedById?: SortOrderInput | SortOrder
    potentialDuplicateOfId?: SortOrderInput | SortOrder
    _count?: ReportCountOrderByAggregateInput
    _avg?: ReportAvgOrderByAggregateInput
    _max?: ReportMaxOrderByAggregateInput
    _min?: ReportMinOrderByAggregateInput
    _sum?: ReportSumOrderByAggregateInput
  }

  export type ReportScalarWhereWithAggregatesInput = {
    AND?: ReportScalarWhereWithAggregatesInput | ReportScalarWhereWithAggregatesInput[]
    OR?: ReportScalarWhereWithAggregatesInput[]
    NOT?: ReportScalarWhereWithAggregatesInput | ReportScalarWhereWithAggregatesInput[]
    id?: StringWithAggregatesFilter<"Report"> | string
    createdAt?: DateTimeWithAggregatesFilter<"Report"> | Date | string
    reportNumber?: StringNullableWithAggregatesFilter<"Report"> | string | null
    siteId?: StringWithAggregatesFilter<"Report"> | string
    reporterId?: StringNullableWithAggregatesFilter<"Report"> | string | null
    description?: StringNullableWithAggregatesFilter<"Report"> | string | null
    mediaUrls?: StringNullableListFilter<"Report">
    category?: StringNullableWithAggregatesFilter<"Report"> | string | null
    severity?: IntNullableWithAggregatesFilter<"Report"> | number | null
    status?: EnumReportStatusWithAggregatesFilter<"Report"> | $Enums.ReportStatus
    moderatedAt?: DateTimeNullableWithAggregatesFilter<"Report"> | Date | string | null
    moderationReason?: StringNullableWithAggregatesFilter<"Report"> | string | null
    moderatedById?: StringNullableWithAggregatesFilter<"Report"> | string | null
    potentialDuplicateOfId?: StringNullableWithAggregatesFilter<"Report"> | string | null
  }

  export type ReportCoReporterWhereInput = {
    AND?: ReportCoReporterWhereInput | ReportCoReporterWhereInput[]
    OR?: ReportCoReporterWhereInput[]
    NOT?: ReportCoReporterWhereInput | ReportCoReporterWhereInput[]
    id?: StringFilter<"ReportCoReporter"> | string
    createdAt?: DateTimeFilter<"ReportCoReporter"> | Date | string
    reportId?: StringFilter<"ReportCoReporter"> | string
    userId?: StringFilter<"ReportCoReporter"> | string
    report?: XOR<ReportScalarRelationFilter, ReportWhereInput>
    user?: XOR<UserScalarRelationFilter, UserWhereInput>
  }

  export type ReportCoReporterOrderByWithRelationInput = {
    id?: SortOrder
    createdAt?: SortOrder
    reportId?: SortOrder
    userId?: SortOrder
    report?: ReportOrderByWithRelationInput
    user?: UserOrderByWithRelationInput
  }

  export type ReportCoReporterWhereUniqueInput = Prisma.AtLeast<{
    id?: string
    reportId_userId?: ReportCoReporterReportIdUserIdCompoundUniqueInput
    AND?: ReportCoReporterWhereInput | ReportCoReporterWhereInput[]
    OR?: ReportCoReporterWhereInput[]
    NOT?: ReportCoReporterWhereInput | ReportCoReporterWhereInput[]
    createdAt?: DateTimeFilter<"ReportCoReporter"> | Date | string
    reportId?: StringFilter<"ReportCoReporter"> | string
    userId?: StringFilter<"ReportCoReporter"> | string
    report?: XOR<ReportScalarRelationFilter, ReportWhereInput>
    user?: XOR<UserScalarRelationFilter, UserWhereInput>
  }, "id" | "reportId_userId">

  export type ReportCoReporterOrderByWithAggregationInput = {
    id?: SortOrder
    createdAt?: SortOrder
    reportId?: SortOrder
    userId?: SortOrder
    _count?: ReportCoReporterCountOrderByAggregateInput
    _max?: ReportCoReporterMaxOrderByAggregateInput
    _min?: ReportCoReporterMinOrderByAggregateInput
  }

  export type ReportCoReporterScalarWhereWithAggregatesInput = {
    AND?: ReportCoReporterScalarWhereWithAggregatesInput | ReportCoReporterScalarWhereWithAggregatesInput[]
    OR?: ReportCoReporterScalarWhereWithAggregatesInput[]
    NOT?: ReportCoReporterScalarWhereWithAggregatesInput | ReportCoReporterScalarWhereWithAggregatesInput[]
    id?: StringWithAggregatesFilter<"ReportCoReporter"> | string
    createdAt?: DateTimeWithAggregatesFilter<"ReportCoReporter"> | Date | string
    reportId?: StringWithAggregatesFilter<"ReportCoReporter"> | string
    userId?: StringWithAggregatesFilter<"ReportCoReporter"> | string
  }

  export type CleanupEventWhereInput = {
    AND?: CleanupEventWhereInput | CleanupEventWhereInput[]
    OR?: CleanupEventWhereInput[]
    NOT?: CleanupEventWhereInput | CleanupEventWhereInput[]
    id?: StringFilter<"CleanupEvent"> | string
    createdAt?: DateTimeFilter<"CleanupEvent"> | Date | string
    updatedAt?: DateTimeFilter<"CleanupEvent"> | Date | string
    siteId?: StringFilter<"CleanupEvent"> | string
    scheduledAt?: DateTimeFilter<"CleanupEvent"> | Date | string
    completedAt?: DateTimeNullableFilter<"CleanupEvent"> | Date | string | null
    organizerId?: StringNullableFilter<"CleanupEvent"> | string | null
    participantCount?: IntFilter<"CleanupEvent"> | number
    site?: XOR<SiteScalarRelationFilter, SiteWhereInput>
  }

  export type CleanupEventOrderByWithRelationInput = {
    id?: SortOrder
    createdAt?: SortOrder
    updatedAt?: SortOrder
    siteId?: SortOrder
    scheduledAt?: SortOrder
    completedAt?: SortOrderInput | SortOrder
    organizerId?: SortOrderInput | SortOrder
    participantCount?: SortOrder
    site?: SiteOrderByWithRelationInput
  }

  export type CleanupEventWhereUniqueInput = Prisma.AtLeast<{
    id?: string
    AND?: CleanupEventWhereInput | CleanupEventWhereInput[]
    OR?: CleanupEventWhereInput[]
    NOT?: CleanupEventWhereInput | CleanupEventWhereInput[]
    createdAt?: DateTimeFilter<"CleanupEvent"> | Date | string
    updatedAt?: DateTimeFilter<"CleanupEvent"> | Date | string
    siteId?: StringFilter<"CleanupEvent"> | string
    scheduledAt?: DateTimeFilter<"CleanupEvent"> | Date | string
    completedAt?: DateTimeNullableFilter<"CleanupEvent"> | Date | string | null
    organizerId?: StringNullableFilter<"CleanupEvent"> | string | null
    participantCount?: IntFilter<"CleanupEvent"> | number
    site?: XOR<SiteScalarRelationFilter, SiteWhereInput>
  }, "id">

  export type CleanupEventOrderByWithAggregationInput = {
    id?: SortOrder
    createdAt?: SortOrder
    updatedAt?: SortOrder
    siteId?: SortOrder
    scheduledAt?: SortOrder
    completedAt?: SortOrderInput | SortOrder
    organizerId?: SortOrderInput | SortOrder
    participantCount?: SortOrder
    _count?: CleanupEventCountOrderByAggregateInput
    _avg?: CleanupEventAvgOrderByAggregateInput
    _max?: CleanupEventMaxOrderByAggregateInput
    _min?: CleanupEventMinOrderByAggregateInput
    _sum?: CleanupEventSumOrderByAggregateInput
  }

  export type CleanupEventScalarWhereWithAggregatesInput = {
    AND?: CleanupEventScalarWhereWithAggregatesInput | CleanupEventScalarWhereWithAggregatesInput[]
    OR?: CleanupEventScalarWhereWithAggregatesInput[]
    NOT?: CleanupEventScalarWhereWithAggregatesInput | CleanupEventScalarWhereWithAggregatesInput[]
    id?: StringWithAggregatesFilter<"CleanupEvent"> | string
    createdAt?: DateTimeWithAggregatesFilter<"CleanupEvent"> | Date | string
    updatedAt?: DateTimeWithAggregatesFilter<"CleanupEvent"> | Date | string
    siteId?: StringWithAggregatesFilter<"CleanupEvent"> | string
    scheduledAt?: DateTimeWithAggregatesFilter<"CleanupEvent"> | Date | string
    completedAt?: DateTimeNullableWithAggregatesFilter<"CleanupEvent"> | Date | string | null
    organizerId?: StringNullableWithAggregatesFilter<"CleanupEvent"> | string | null
    participantCount?: IntWithAggregatesFilter<"CleanupEvent"> | number
  }

  export type UserCreateInput = {
    id?: string
    createdAt?: Date | string
    updatedAt?: Date | string
    firstName: string
    lastName: string
    email: string
    phoneNumber: string
    passwordHash: string
    role?: $Enums.Role
    status?: $Enums.UserStatus
    isPhoneVerified?: boolean
    pointsBalance?: number
    totalPointsEarned?: number
    totalPointsSpent?: number
    lastActiveAt?: Date | string | null
    reports?: ReportCreateNestedManyWithoutReporterInput
    moderatedReports?: ReportCreateNestedManyWithoutModeratedByInput
    adminNotifications?: AdminNotificationCreateNestedManyWithoutUserInput
    pointTransactions?: PointTransactionCreateNestedManyWithoutUserInput
    coReportedReports?: ReportCoReporterCreateNestedManyWithoutUserInput
    sessions?: UserSessionCreateNestedManyWithoutUserInput
  }

  export type UserUncheckedCreateInput = {
    id?: string
    createdAt?: Date | string
    updatedAt?: Date | string
    firstName: string
    lastName: string
    email: string
    phoneNumber: string
    passwordHash: string
    role?: $Enums.Role
    status?: $Enums.UserStatus
    isPhoneVerified?: boolean
    pointsBalance?: number
    totalPointsEarned?: number
    totalPointsSpent?: number
    lastActiveAt?: Date | string | null
    reports?: ReportUncheckedCreateNestedManyWithoutReporterInput
    moderatedReports?: ReportUncheckedCreateNestedManyWithoutModeratedByInput
    adminNotifications?: AdminNotificationUncheckedCreateNestedManyWithoutUserInput
    pointTransactions?: PointTransactionUncheckedCreateNestedManyWithoutUserInput
    coReportedReports?: ReportCoReporterUncheckedCreateNestedManyWithoutUserInput
    sessions?: UserSessionUncheckedCreateNestedManyWithoutUserInput
  }

  export type UserUpdateInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    updatedAt?: DateTimeFieldUpdateOperationsInput | Date | string
    firstName?: StringFieldUpdateOperationsInput | string
    lastName?: StringFieldUpdateOperationsInput | string
    email?: StringFieldUpdateOperationsInput | string
    phoneNumber?: StringFieldUpdateOperationsInput | string
    passwordHash?: StringFieldUpdateOperationsInput | string
    role?: EnumRoleFieldUpdateOperationsInput | $Enums.Role
    status?: EnumUserStatusFieldUpdateOperationsInput | $Enums.UserStatus
    isPhoneVerified?: BoolFieldUpdateOperationsInput | boolean
    pointsBalance?: IntFieldUpdateOperationsInput | number
    totalPointsEarned?: IntFieldUpdateOperationsInput | number
    totalPointsSpent?: IntFieldUpdateOperationsInput | number
    lastActiveAt?: NullableDateTimeFieldUpdateOperationsInput | Date | string | null
    reports?: ReportUpdateManyWithoutReporterNestedInput
    moderatedReports?: ReportUpdateManyWithoutModeratedByNestedInput
    adminNotifications?: AdminNotificationUpdateManyWithoutUserNestedInput
    pointTransactions?: PointTransactionUpdateManyWithoutUserNestedInput
    coReportedReports?: ReportCoReporterUpdateManyWithoutUserNestedInput
    sessions?: UserSessionUpdateManyWithoutUserNestedInput
  }

  export type UserUncheckedUpdateInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    updatedAt?: DateTimeFieldUpdateOperationsInput | Date | string
    firstName?: StringFieldUpdateOperationsInput | string
    lastName?: StringFieldUpdateOperationsInput | string
    email?: StringFieldUpdateOperationsInput | string
    phoneNumber?: StringFieldUpdateOperationsInput | string
    passwordHash?: StringFieldUpdateOperationsInput | string
    role?: EnumRoleFieldUpdateOperationsInput | $Enums.Role
    status?: EnumUserStatusFieldUpdateOperationsInput | $Enums.UserStatus
    isPhoneVerified?: BoolFieldUpdateOperationsInput | boolean
    pointsBalance?: IntFieldUpdateOperationsInput | number
    totalPointsEarned?: IntFieldUpdateOperationsInput | number
    totalPointsSpent?: IntFieldUpdateOperationsInput | number
    lastActiveAt?: NullableDateTimeFieldUpdateOperationsInput | Date | string | null
    reports?: ReportUncheckedUpdateManyWithoutReporterNestedInput
    moderatedReports?: ReportUncheckedUpdateManyWithoutModeratedByNestedInput
    adminNotifications?: AdminNotificationUncheckedUpdateManyWithoutUserNestedInput
    pointTransactions?: PointTransactionUncheckedUpdateManyWithoutUserNestedInput
    coReportedReports?: ReportCoReporterUncheckedUpdateManyWithoutUserNestedInput
    sessions?: UserSessionUncheckedUpdateManyWithoutUserNestedInput
  }

  export type UserCreateManyInput = {
    id?: string
    createdAt?: Date | string
    updatedAt?: Date | string
    firstName: string
    lastName: string
    email: string
    phoneNumber: string
    passwordHash: string
    role?: $Enums.Role
    status?: $Enums.UserStatus
    isPhoneVerified?: boolean
    pointsBalance?: number
    totalPointsEarned?: number
    totalPointsSpent?: number
    lastActiveAt?: Date | string | null
  }

  export type UserUpdateManyMutationInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    updatedAt?: DateTimeFieldUpdateOperationsInput | Date | string
    firstName?: StringFieldUpdateOperationsInput | string
    lastName?: StringFieldUpdateOperationsInput | string
    email?: StringFieldUpdateOperationsInput | string
    phoneNumber?: StringFieldUpdateOperationsInput | string
    passwordHash?: StringFieldUpdateOperationsInput | string
    role?: EnumRoleFieldUpdateOperationsInput | $Enums.Role
    status?: EnumUserStatusFieldUpdateOperationsInput | $Enums.UserStatus
    isPhoneVerified?: BoolFieldUpdateOperationsInput | boolean
    pointsBalance?: IntFieldUpdateOperationsInput | number
    totalPointsEarned?: IntFieldUpdateOperationsInput | number
    totalPointsSpent?: IntFieldUpdateOperationsInput | number
    lastActiveAt?: NullableDateTimeFieldUpdateOperationsInput | Date | string | null
  }

  export type UserUncheckedUpdateManyInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    updatedAt?: DateTimeFieldUpdateOperationsInput | Date | string
    firstName?: StringFieldUpdateOperationsInput | string
    lastName?: StringFieldUpdateOperationsInput | string
    email?: StringFieldUpdateOperationsInput | string
    phoneNumber?: StringFieldUpdateOperationsInput | string
    passwordHash?: StringFieldUpdateOperationsInput | string
    role?: EnumRoleFieldUpdateOperationsInput | $Enums.Role
    status?: EnumUserStatusFieldUpdateOperationsInput | $Enums.UserStatus
    isPhoneVerified?: BoolFieldUpdateOperationsInput | boolean
    pointsBalance?: IntFieldUpdateOperationsInput | number
    totalPointsEarned?: IntFieldUpdateOperationsInput | number
    totalPointsSpent?: IntFieldUpdateOperationsInput | number
    lastActiveAt?: NullableDateTimeFieldUpdateOperationsInput | Date | string | null
  }

  export type UserSessionCreateInput = {
    id?: string
    createdAt?: Date | string
    tokenId: string
    refreshTokenHash: string
    deviceInfo?: string | null
    ipAddress?: string | null
    expiresAt: Date | string
    revokedAt?: Date | string | null
    user: UserCreateNestedOneWithoutSessionsInput
  }

  export type UserSessionUncheckedCreateInput = {
    id?: string
    createdAt?: Date | string
    userId: string
    tokenId: string
    refreshTokenHash: string
    deviceInfo?: string | null
    ipAddress?: string | null
    expiresAt: Date | string
    revokedAt?: Date | string | null
  }

  export type UserSessionUpdateInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    tokenId?: StringFieldUpdateOperationsInput | string
    refreshTokenHash?: StringFieldUpdateOperationsInput | string
    deviceInfo?: NullableStringFieldUpdateOperationsInput | string | null
    ipAddress?: NullableStringFieldUpdateOperationsInput | string | null
    expiresAt?: DateTimeFieldUpdateOperationsInput | Date | string
    revokedAt?: NullableDateTimeFieldUpdateOperationsInput | Date | string | null
    user?: UserUpdateOneRequiredWithoutSessionsNestedInput
  }

  export type UserSessionUncheckedUpdateInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    userId?: StringFieldUpdateOperationsInput | string
    tokenId?: StringFieldUpdateOperationsInput | string
    refreshTokenHash?: StringFieldUpdateOperationsInput | string
    deviceInfo?: NullableStringFieldUpdateOperationsInput | string | null
    ipAddress?: NullableStringFieldUpdateOperationsInput | string | null
    expiresAt?: DateTimeFieldUpdateOperationsInput | Date | string
    revokedAt?: NullableDateTimeFieldUpdateOperationsInput | Date | string | null
  }

  export type UserSessionCreateManyInput = {
    id?: string
    createdAt?: Date | string
    userId: string
    tokenId: string
    refreshTokenHash: string
    deviceInfo?: string | null
    ipAddress?: string | null
    expiresAt: Date | string
    revokedAt?: Date | string | null
  }

  export type UserSessionUpdateManyMutationInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    tokenId?: StringFieldUpdateOperationsInput | string
    refreshTokenHash?: StringFieldUpdateOperationsInput | string
    deviceInfo?: NullableStringFieldUpdateOperationsInput | string | null
    ipAddress?: NullableStringFieldUpdateOperationsInput | string | null
    expiresAt?: DateTimeFieldUpdateOperationsInput | Date | string
    revokedAt?: NullableDateTimeFieldUpdateOperationsInput | Date | string | null
  }

  export type UserSessionUncheckedUpdateManyInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    userId?: StringFieldUpdateOperationsInput | string
    tokenId?: StringFieldUpdateOperationsInput | string
    refreshTokenHash?: StringFieldUpdateOperationsInput | string
    deviceInfo?: NullableStringFieldUpdateOperationsInput | string | null
    ipAddress?: NullableStringFieldUpdateOperationsInput | string | null
    expiresAt?: DateTimeFieldUpdateOperationsInput | Date | string
    revokedAt?: NullableDateTimeFieldUpdateOperationsInput | Date | string | null
  }

  export type PhoneOtpCreateInput = {
    id?: string
    createdAt?: Date | string
    phoneNumber: string
    code: string
    expiresAt: Date | string
    attemptCount?: number
  }

  export type PhoneOtpUncheckedCreateInput = {
    id?: string
    createdAt?: Date | string
    phoneNumber: string
    code: string
    expiresAt: Date | string
    attemptCount?: number
  }

  export type PhoneOtpUpdateInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    phoneNumber?: StringFieldUpdateOperationsInput | string
    code?: StringFieldUpdateOperationsInput | string
    expiresAt?: DateTimeFieldUpdateOperationsInput | Date | string
    attemptCount?: IntFieldUpdateOperationsInput | number
  }

  export type PhoneOtpUncheckedUpdateInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    phoneNumber?: StringFieldUpdateOperationsInput | string
    code?: StringFieldUpdateOperationsInput | string
    expiresAt?: DateTimeFieldUpdateOperationsInput | Date | string
    attemptCount?: IntFieldUpdateOperationsInput | number
  }

  export type PhoneOtpCreateManyInput = {
    id?: string
    createdAt?: Date | string
    phoneNumber: string
    code: string
    expiresAt: Date | string
    attemptCount?: number
  }

  export type PhoneOtpUpdateManyMutationInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    phoneNumber?: StringFieldUpdateOperationsInput | string
    code?: StringFieldUpdateOperationsInput | string
    expiresAt?: DateTimeFieldUpdateOperationsInput | Date | string
    attemptCount?: IntFieldUpdateOperationsInput | number
  }

  export type PhoneOtpUncheckedUpdateManyInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    phoneNumber?: StringFieldUpdateOperationsInput | string
    code?: StringFieldUpdateOperationsInput | string
    expiresAt?: DateTimeFieldUpdateOperationsInput | Date | string
    attemptCount?: IntFieldUpdateOperationsInput | number
  }

  export type LoginFailureCreateInput = {
    id?: string
    phoneNumber: string
    firstFailedAt: Date | string
    attemptCount: number
  }

  export type LoginFailureUncheckedCreateInput = {
    id?: string
    phoneNumber: string
    firstFailedAt: Date | string
    attemptCount: number
  }

  export type LoginFailureUpdateInput = {
    id?: StringFieldUpdateOperationsInput | string
    phoneNumber?: StringFieldUpdateOperationsInput | string
    firstFailedAt?: DateTimeFieldUpdateOperationsInput | Date | string
    attemptCount?: IntFieldUpdateOperationsInput | number
  }

  export type LoginFailureUncheckedUpdateInput = {
    id?: StringFieldUpdateOperationsInput | string
    phoneNumber?: StringFieldUpdateOperationsInput | string
    firstFailedAt?: DateTimeFieldUpdateOperationsInput | Date | string
    attemptCount?: IntFieldUpdateOperationsInput | number
  }

  export type LoginFailureCreateManyInput = {
    id?: string
    phoneNumber: string
    firstFailedAt: Date | string
    attemptCount: number
  }

  export type LoginFailureUpdateManyMutationInput = {
    id?: StringFieldUpdateOperationsInput | string
    phoneNumber?: StringFieldUpdateOperationsInput | string
    firstFailedAt?: DateTimeFieldUpdateOperationsInput | Date | string
    attemptCount?: IntFieldUpdateOperationsInput | number
  }

  export type LoginFailureUncheckedUpdateManyInput = {
    id?: StringFieldUpdateOperationsInput | string
    phoneNumber?: StringFieldUpdateOperationsInput | string
    firstFailedAt?: DateTimeFieldUpdateOperationsInput | Date | string
    attemptCount?: IntFieldUpdateOperationsInput | number
  }

  export type AdminNotificationCreateInput = {
    id?: string
    createdAt?: Date | string
    updatedAt?: Date | string
    title: string
    message: string
    timeLabel: string
    tone: $Enums.AdminNotificationTone
    category: $Enums.AdminNotificationCategory
    isUnread?: boolean
    href?: string | null
    user?: UserCreateNestedOneWithoutAdminNotificationsInput
  }

  export type AdminNotificationUncheckedCreateInput = {
    id?: string
    createdAt?: Date | string
    updatedAt?: Date | string
    userId?: string | null
    title: string
    message: string
    timeLabel: string
    tone: $Enums.AdminNotificationTone
    category: $Enums.AdminNotificationCategory
    isUnread?: boolean
    href?: string | null
  }

  export type AdminNotificationUpdateInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    updatedAt?: DateTimeFieldUpdateOperationsInput | Date | string
    title?: StringFieldUpdateOperationsInput | string
    message?: StringFieldUpdateOperationsInput | string
    timeLabel?: StringFieldUpdateOperationsInput | string
    tone?: EnumAdminNotificationToneFieldUpdateOperationsInput | $Enums.AdminNotificationTone
    category?: EnumAdminNotificationCategoryFieldUpdateOperationsInput | $Enums.AdminNotificationCategory
    isUnread?: BoolFieldUpdateOperationsInput | boolean
    href?: NullableStringFieldUpdateOperationsInput | string | null
    user?: UserUpdateOneWithoutAdminNotificationsNestedInput
  }

  export type AdminNotificationUncheckedUpdateInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    updatedAt?: DateTimeFieldUpdateOperationsInput | Date | string
    userId?: NullableStringFieldUpdateOperationsInput | string | null
    title?: StringFieldUpdateOperationsInput | string
    message?: StringFieldUpdateOperationsInput | string
    timeLabel?: StringFieldUpdateOperationsInput | string
    tone?: EnumAdminNotificationToneFieldUpdateOperationsInput | $Enums.AdminNotificationTone
    category?: EnumAdminNotificationCategoryFieldUpdateOperationsInput | $Enums.AdminNotificationCategory
    isUnread?: BoolFieldUpdateOperationsInput | boolean
    href?: NullableStringFieldUpdateOperationsInput | string | null
  }

  export type AdminNotificationCreateManyInput = {
    id?: string
    createdAt?: Date | string
    updatedAt?: Date | string
    userId?: string | null
    title: string
    message: string
    timeLabel: string
    tone: $Enums.AdminNotificationTone
    category: $Enums.AdminNotificationCategory
    isUnread?: boolean
    href?: string | null
  }

  export type AdminNotificationUpdateManyMutationInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    updatedAt?: DateTimeFieldUpdateOperationsInput | Date | string
    title?: StringFieldUpdateOperationsInput | string
    message?: StringFieldUpdateOperationsInput | string
    timeLabel?: StringFieldUpdateOperationsInput | string
    tone?: EnumAdminNotificationToneFieldUpdateOperationsInput | $Enums.AdminNotificationTone
    category?: EnumAdminNotificationCategoryFieldUpdateOperationsInput | $Enums.AdminNotificationCategory
    isUnread?: BoolFieldUpdateOperationsInput | boolean
    href?: NullableStringFieldUpdateOperationsInput | string | null
  }

  export type AdminNotificationUncheckedUpdateManyInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    updatedAt?: DateTimeFieldUpdateOperationsInput | Date | string
    userId?: NullableStringFieldUpdateOperationsInput | string | null
    title?: StringFieldUpdateOperationsInput | string
    message?: StringFieldUpdateOperationsInput | string
    timeLabel?: StringFieldUpdateOperationsInput | string
    tone?: EnumAdminNotificationToneFieldUpdateOperationsInput | $Enums.AdminNotificationTone
    category?: EnumAdminNotificationCategoryFieldUpdateOperationsInput | $Enums.AdminNotificationCategory
    isUnread?: BoolFieldUpdateOperationsInput | boolean
    href?: NullableStringFieldUpdateOperationsInput | string | null
  }

  export type PointTransactionCreateInput = {
    id?: string
    createdAt?: Date | string
    delta: number
    balanceAfter: number
    reasonCode: string
    referenceType?: string | null
    referenceId?: string | null
    metadata?: NullableJsonNullValueInput | InputJsonValue
    user: UserCreateNestedOneWithoutPointTransactionsInput
  }

  export type PointTransactionUncheckedCreateInput = {
    id?: string
    createdAt?: Date | string
    userId: string
    delta: number
    balanceAfter: number
    reasonCode: string
    referenceType?: string | null
    referenceId?: string | null
    metadata?: NullableJsonNullValueInput | InputJsonValue
  }

  export type PointTransactionUpdateInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    delta?: IntFieldUpdateOperationsInput | number
    balanceAfter?: IntFieldUpdateOperationsInput | number
    reasonCode?: StringFieldUpdateOperationsInput | string
    referenceType?: NullableStringFieldUpdateOperationsInput | string | null
    referenceId?: NullableStringFieldUpdateOperationsInput | string | null
    metadata?: NullableJsonNullValueInput | InputJsonValue
    user?: UserUpdateOneRequiredWithoutPointTransactionsNestedInput
  }

  export type PointTransactionUncheckedUpdateInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    userId?: StringFieldUpdateOperationsInput | string
    delta?: IntFieldUpdateOperationsInput | number
    balanceAfter?: IntFieldUpdateOperationsInput | number
    reasonCode?: StringFieldUpdateOperationsInput | string
    referenceType?: NullableStringFieldUpdateOperationsInput | string | null
    referenceId?: NullableStringFieldUpdateOperationsInput | string | null
    metadata?: NullableJsonNullValueInput | InputJsonValue
  }

  export type PointTransactionCreateManyInput = {
    id?: string
    createdAt?: Date | string
    userId: string
    delta: number
    balanceAfter: number
    reasonCode: string
    referenceType?: string | null
    referenceId?: string | null
    metadata?: NullableJsonNullValueInput | InputJsonValue
  }

  export type PointTransactionUpdateManyMutationInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    delta?: IntFieldUpdateOperationsInput | number
    balanceAfter?: IntFieldUpdateOperationsInput | number
    reasonCode?: StringFieldUpdateOperationsInput | string
    referenceType?: NullableStringFieldUpdateOperationsInput | string | null
    referenceId?: NullableStringFieldUpdateOperationsInput | string | null
    metadata?: NullableJsonNullValueInput | InputJsonValue
  }

  export type PointTransactionUncheckedUpdateManyInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    userId?: StringFieldUpdateOperationsInput | string
    delta?: IntFieldUpdateOperationsInput | number
    balanceAfter?: IntFieldUpdateOperationsInput | number
    reasonCode?: StringFieldUpdateOperationsInput | string
    referenceType?: NullableStringFieldUpdateOperationsInput | string | null
    referenceId?: NullableStringFieldUpdateOperationsInput | string | null
    metadata?: NullableJsonNullValueInput | InputJsonValue
  }

  export type SiteCreateInput = {
    id?: string
    createdAt?: Date | string
    updatedAt?: Date | string
    latitude: number
    longitude: number
    description?: string | null
    status?: $Enums.SiteStatus
    reports?: ReportCreateNestedManyWithoutSiteInput
    events?: CleanupEventCreateNestedManyWithoutSiteInput
  }

  export type SiteUncheckedCreateInput = {
    id?: string
    createdAt?: Date | string
    updatedAt?: Date | string
    latitude: number
    longitude: number
    description?: string | null
    status?: $Enums.SiteStatus
    reports?: ReportUncheckedCreateNestedManyWithoutSiteInput
    events?: CleanupEventUncheckedCreateNestedManyWithoutSiteInput
  }

  export type SiteUpdateInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    updatedAt?: DateTimeFieldUpdateOperationsInput | Date | string
    latitude?: FloatFieldUpdateOperationsInput | number
    longitude?: FloatFieldUpdateOperationsInput | number
    description?: NullableStringFieldUpdateOperationsInput | string | null
    status?: EnumSiteStatusFieldUpdateOperationsInput | $Enums.SiteStatus
    reports?: ReportUpdateManyWithoutSiteNestedInput
    events?: CleanupEventUpdateManyWithoutSiteNestedInput
  }

  export type SiteUncheckedUpdateInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    updatedAt?: DateTimeFieldUpdateOperationsInput | Date | string
    latitude?: FloatFieldUpdateOperationsInput | number
    longitude?: FloatFieldUpdateOperationsInput | number
    description?: NullableStringFieldUpdateOperationsInput | string | null
    status?: EnumSiteStatusFieldUpdateOperationsInput | $Enums.SiteStatus
    reports?: ReportUncheckedUpdateManyWithoutSiteNestedInput
    events?: CleanupEventUncheckedUpdateManyWithoutSiteNestedInput
  }

  export type SiteCreateManyInput = {
    id?: string
    createdAt?: Date | string
    updatedAt?: Date | string
    latitude: number
    longitude: number
    description?: string | null
    status?: $Enums.SiteStatus
  }

  export type SiteUpdateManyMutationInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    updatedAt?: DateTimeFieldUpdateOperationsInput | Date | string
    latitude?: FloatFieldUpdateOperationsInput | number
    longitude?: FloatFieldUpdateOperationsInput | number
    description?: NullableStringFieldUpdateOperationsInput | string | null
    status?: EnumSiteStatusFieldUpdateOperationsInput | $Enums.SiteStatus
  }

  export type SiteUncheckedUpdateManyInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    updatedAt?: DateTimeFieldUpdateOperationsInput | Date | string
    latitude?: FloatFieldUpdateOperationsInput | number
    longitude?: FloatFieldUpdateOperationsInput | number
    description?: NullableStringFieldUpdateOperationsInput | string | null
    status?: EnumSiteStatusFieldUpdateOperationsInput | $Enums.SiteStatus
  }

  export type ReportCreateInput = {
    id?: string
    createdAt?: Date | string
    reportNumber?: string | null
    description?: string | null
    mediaUrls?: ReportCreatemediaUrlsInput | string[]
    category?: string | null
    severity?: number | null
    status?: $Enums.ReportStatus
    moderatedAt?: Date | string | null
    moderationReason?: string | null
    site: SiteCreateNestedOneWithoutReportsInput
    reporter?: UserCreateNestedOneWithoutReportsInput
    moderatedBy?: UserCreateNestedOneWithoutModeratedReportsInput
    potentialDuplicateOf?: ReportCreateNestedOneWithoutPotentialDuplicatesInput
    potentialDuplicates?: ReportCreateNestedManyWithoutPotentialDuplicateOfInput
    coReporters?: ReportCoReporterCreateNestedManyWithoutReportInput
  }

  export type ReportUncheckedCreateInput = {
    id?: string
    createdAt?: Date | string
    reportNumber?: string | null
    siteId: string
    reporterId?: string | null
    description?: string | null
    mediaUrls?: ReportCreatemediaUrlsInput | string[]
    category?: string | null
    severity?: number | null
    status?: $Enums.ReportStatus
    moderatedAt?: Date | string | null
    moderationReason?: string | null
    moderatedById?: string | null
    potentialDuplicateOfId?: string | null
    potentialDuplicates?: ReportUncheckedCreateNestedManyWithoutPotentialDuplicateOfInput
    coReporters?: ReportCoReporterUncheckedCreateNestedManyWithoutReportInput
  }

  export type ReportUpdateInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    reportNumber?: NullableStringFieldUpdateOperationsInput | string | null
    description?: NullableStringFieldUpdateOperationsInput | string | null
    mediaUrls?: ReportUpdatemediaUrlsInput | string[]
    category?: NullableStringFieldUpdateOperationsInput | string | null
    severity?: NullableIntFieldUpdateOperationsInput | number | null
    status?: EnumReportStatusFieldUpdateOperationsInput | $Enums.ReportStatus
    moderatedAt?: NullableDateTimeFieldUpdateOperationsInput | Date | string | null
    moderationReason?: NullableStringFieldUpdateOperationsInput | string | null
    site?: SiteUpdateOneRequiredWithoutReportsNestedInput
    reporter?: UserUpdateOneWithoutReportsNestedInput
    moderatedBy?: UserUpdateOneWithoutModeratedReportsNestedInput
    potentialDuplicateOf?: ReportUpdateOneWithoutPotentialDuplicatesNestedInput
    potentialDuplicates?: ReportUpdateManyWithoutPotentialDuplicateOfNestedInput
    coReporters?: ReportCoReporterUpdateManyWithoutReportNestedInput
  }

  export type ReportUncheckedUpdateInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    reportNumber?: NullableStringFieldUpdateOperationsInput | string | null
    siteId?: StringFieldUpdateOperationsInput | string
    reporterId?: NullableStringFieldUpdateOperationsInput | string | null
    description?: NullableStringFieldUpdateOperationsInput | string | null
    mediaUrls?: ReportUpdatemediaUrlsInput | string[]
    category?: NullableStringFieldUpdateOperationsInput | string | null
    severity?: NullableIntFieldUpdateOperationsInput | number | null
    status?: EnumReportStatusFieldUpdateOperationsInput | $Enums.ReportStatus
    moderatedAt?: NullableDateTimeFieldUpdateOperationsInput | Date | string | null
    moderationReason?: NullableStringFieldUpdateOperationsInput | string | null
    moderatedById?: NullableStringFieldUpdateOperationsInput | string | null
    potentialDuplicateOfId?: NullableStringFieldUpdateOperationsInput | string | null
    potentialDuplicates?: ReportUncheckedUpdateManyWithoutPotentialDuplicateOfNestedInput
    coReporters?: ReportCoReporterUncheckedUpdateManyWithoutReportNestedInput
  }

  export type ReportCreateManyInput = {
    id?: string
    createdAt?: Date | string
    reportNumber?: string | null
    siteId: string
    reporterId?: string | null
    description?: string | null
    mediaUrls?: ReportCreatemediaUrlsInput | string[]
    category?: string | null
    severity?: number | null
    status?: $Enums.ReportStatus
    moderatedAt?: Date | string | null
    moderationReason?: string | null
    moderatedById?: string | null
    potentialDuplicateOfId?: string | null
  }

  export type ReportUpdateManyMutationInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    reportNumber?: NullableStringFieldUpdateOperationsInput | string | null
    description?: NullableStringFieldUpdateOperationsInput | string | null
    mediaUrls?: ReportUpdatemediaUrlsInput | string[]
    category?: NullableStringFieldUpdateOperationsInput | string | null
    severity?: NullableIntFieldUpdateOperationsInput | number | null
    status?: EnumReportStatusFieldUpdateOperationsInput | $Enums.ReportStatus
    moderatedAt?: NullableDateTimeFieldUpdateOperationsInput | Date | string | null
    moderationReason?: NullableStringFieldUpdateOperationsInput | string | null
  }

  export type ReportUncheckedUpdateManyInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    reportNumber?: NullableStringFieldUpdateOperationsInput | string | null
    siteId?: StringFieldUpdateOperationsInput | string
    reporterId?: NullableStringFieldUpdateOperationsInput | string | null
    description?: NullableStringFieldUpdateOperationsInput | string | null
    mediaUrls?: ReportUpdatemediaUrlsInput | string[]
    category?: NullableStringFieldUpdateOperationsInput | string | null
    severity?: NullableIntFieldUpdateOperationsInput | number | null
    status?: EnumReportStatusFieldUpdateOperationsInput | $Enums.ReportStatus
    moderatedAt?: NullableDateTimeFieldUpdateOperationsInput | Date | string | null
    moderationReason?: NullableStringFieldUpdateOperationsInput | string | null
    moderatedById?: NullableStringFieldUpdateOperationsInput | string | null
    potentialDuplicateOfId?: NullableStringFieldUpdateOperationsInput | string | null
  }

  export type ReportCoReporterCreateInput = {
    id?: string
    createdAt?: Date | string
    report: ReportCreateNestedOneWithoutCoReportersInput
    user: UserCreateNestedOneWithoutCoReportedReportsInput
  }

  export type ReportCoReporterUncheckedCreateInput = {
    id?: string
    createdAt?: Date | string
    reportId: string
    userId: string
  }

  export type ReportCoReporterUpdateInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    report?: ReportUpdateOneRequiredWithoutCoReportersNestedInput
    user?: UserUpdateOneRequiredWithoutCoReportedReportsNestedInput
  }

  export type ReportCoReporterUncheckedUpdateInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    reportId?: StringFieldUpdateOperationsInput | string
    userId?: StringFieldUpdateOperationsInput | string
  }

  export type ReportCoReporterCreateManyInput = {
    id?: string
    createdAt?: Date | string
    reportId: string
    userId: string
  }

  export type ReportCoReporterUpdateManyMutationInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
  }

  export type ReportCoReporterUncheckedUpdateManyInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    reportId?: StringFieldUpdateOperationsInput | string
    userId?: StringFieldUpdateOperationsInput | string
  }

  export type CleanupEventCreateInput = {
    id?: string
    createdAt?: Date | string
    updatedAt?: Date | string
    scheduledAt: Date | string
    completedAt?: Date | string | null
    organizerId?: string | null
    participantCount?: number
    site: SiteCreateNestedOneWithoutEventsInput
  }

  export type CleanupEventUncheckedCreateInput = {
    id?: string
    createdAt?: Date | string
    updatedAt?: Date | string
    siteId: string
    scheduledAt: Date | string
    completedAt?: Date | string | null
    organizerId?: string | null
    participantCount?: number
  }

  export type CleanupEventUpdateInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    updatedAt?: DateTimeFieldUpdateOperationsInput | Date | string
    scheduledAt?: DateTimeFieldUpdateOperationsInput | Date | string
    completedAt?: NullableDateTimeFieldUpdateOperationsInput | Date | string | null
    organizerId?: NullableStringFieldUpdateOperationsInput | string | null
    participantCount?: IntFieldUpdateOperationsInput | number
    site?: SiteUpdateOneRequiredWithoutEventsNestedInput
  }

  export type CleanupEventUncheckedUpdateInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    updatedAt?: DateTimeFieldUpdateOperationsInput | Date | string
    siteId?: StringFieldUpdateOperationsInput | string
    scheduledAt?: DateTimeFieldUpdateOperationsInput | Date | string
    completedAt?: NullableDateTimeFieldUpdateOperationsInput | Date | string | null
    organizerId?: NullableStringFieldUpdateOperationsInput | string | null
    participantCount?: IntFieldUpdateOperationsInput | number
  }

  export type CleanupEventCreateManyInput = {
    id?: string
    createdAt?: Date | string
    updatedAt?: Date | string
    siteId: string
    scheduledAt: Date | string
    completedAt?: Date | string | null
    organizerId?: string | null
    participantCount?: number
  }

  export type CleanupEventUpdateManyMutationInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    updatedAt?: DateTimeFieldUpdateOperationsInput | Date | string
    scheduledAt?: DateTimeFieldUpdateOperationsInput | Date | string
    completedAt?: NullableDateTimeFieldUpdateOperationsInput | Date | string | null
    organizerId?: NullableStringFieldUpdateOperationsInput | string | null
    participantCount?: IntFieldUpdateOperationsInput | number
  }

  export type CleanupEventUncheckedUpdateManyInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    updatedAt?: DateTimeFieldUpdateOperationsInput | Date | string
    siteId?: StringFieldUpdateOperationsInput | string
    scheduledAt?: DateTimeFieldUpdateOperationsInput | Date | string
    completedAt?: NullableDateTimeFieldUpdateOperationsInput | Date | string | null
    organizerId?: NullableStringFieldUpdateOperationsInput | string | null
    participantCount?: IntFieldUpdateOperationsInput | number
  }

  export type StringFilter<$PrismaModel = never> = {
    equals?: string | StringFieldRefInput<$PrismaModel>
    in?: string[] | ListStringFieldRefInput<$PrismaModel>
    notIn?: string[] | ListStringFieldRefInput<$PrismaModel>
    lt?: string | StringFieldRefInput<$PrismaModel>
    lte?: string | StringFieldRefInput<$PrismaModel>
    gt?: string | StringFieldRefInput<$PrismaModel>
    gte?: string | StringFieldRefInput<$PrismaModel>
    contains?: string | StringFieldRefInput<$PrismaModel>
    startsWith?: string | StringFieldRefInput<$PrismaModel>
    endsWith?: string | StringFieldRefInput<$PrismaModel>
    mode?: QueryMode
    not?: NestedStringFilter<$PrismaModel> | string
  }

  export type DateTimeFilter<$PrismaModel = never> = {
    equals?: Date | string | DateTimeFieldRefInput<$PrismaModel>
    in?: Date[] | string[] | ListDateTimeFieldRefInput<$PrismaModel>
    notIn?: Date[] | string[] | ListDateTimeFieldRefInput<$PrismaModel>
    lt?: Date | string | DateTimeFieldRefInput<$PrismaModel>
    lte?: Date | string | DateTimeFieldRefInput<$PrismaModel>
    gt?: Date | string | DateTimeFieldRefInput<$PrismaModel>
    gte?: Date | string | DateTimeFieldRefInput<$PrismaModel>
    not?: NestedDateTimeFilter<$PrismaModel> | Date | string
  }

  export type EnumRoleFilter<$PrismaModel = never> = {
    equals?: $Enums.Role | EnumRoleFieldRefInput<$PrismaModel>
    in?: $Enums.Role[] | ListEnumRoleFieldRefInput<$PrismaModel>
    notIn?: $Enums.Role[] | ListEnumRoleFieldRefInput<$PrismaModel>
    not?: NestedEnumRoleFilter<$PrismaModel> | $Enums.Role
  }

  export type EnumUserStatusFilter<$PrismaModel = never> = {
    equals?: $Enums.UserStatus | EnumUserStatusFieldRefInput<$PrismaModel>
    in?: $Enums.UserStatus[] | ListEnumUserStatusFieldRefInput<$PrismaModel>
    notIn?: $Enums.UserStatus[] | ListEnumUserStatusFieldRefInput<$PrismaModel>
    not?: NestedEnumUserStatusFilter<$PrismaModel> | $Enums.UserStatus
  }

  export type BoolFilter<$PrismaModel = never> = {
    equals?: boolean | BooleanFieldRefInput<$PrismaModel>
    not?: NestedBoolFilter<$PrismaModel> | boolean
  }

  export type IntFilter<$PrismaModel = never> = {
    equals?: number | IntFieldRefInput<$PrismaModel>
    in?: number[] | ListIntFieldRefInput<$PrismaModel>
    notIn?: number[] | ListIntFieldRefInput<$PrismaModel>
    lt?: number | IntFieldRefInput<$PrismaModel>
    lte?: number | IntFieldRefInput<$PrismaModel>
    gt?: number | IntFieldRefInput<$PrismaModel>
    gte?: number | IntFieldRefInput<$PrismaModel>
    not?: NestedIntFilter<$PrismaModel> | number
  }

  export type DateTimeNullableFilter<$PrismaModel = never> = {
    equals?: Date | string | DateTimeFieldRefInput<$PrismaModel> | null
    in?: Date[] | string[] | ListDateTimeFieldRefInput<$PrismaModel> | null
    notIn?: Date[] | string[] | ListDateTimeFieldRefInput<$PrismaModel> | null
    lt?: Date | string | DateTimeFieldRefInput<$PrismaModel>
    lte?: Date | string | DateTimeFieldRefInput<$PrismaModel>
    gt?: Date | string | DateTimeFieldRefInput<$PrismaModel>
    gte?: Date | string | DateTimeFieldRefInput<$PrismaModel>
    not?: NestedDateTimeNullableFilter<$PrismaModel> | Date | string | null
  }

  export type ReportListRelationFilter = {
    every?: ReportWhereInput
    some?: ReportWhereInput
    none?: ReportWhereInput
  }

  export type AdminNotificationListRelationFilter = {
    every?: AdminNotificationWhereInput
    some?: AdminNotificationWhereInput
    none?: AdminNotificationWhereInput
  }

  export type PointTransactionListRelationFilter = {
    every?: PointTransactionWhereInput
    some?: PointTransactionWhereInput
    none?: PointTransactionWhereInput
  }

  export type ReportCoReporterListRelationFilter = {
    every?: ReportCoReporterWhereInput
    some?: ReportCoReporterWhereInput
    none?: ReportCoReporterWhereInput
  }

  export type UserSessionListRelationFilter = {
    every?: UserSessionWhereInput
    some?: UserSessionWhereInput
    none?: UserSessionWhereInput
  }

  export type SortOrderInput = {
    sort: SortOrder
    nulls?: NullsOrder
  }

  export type ReportOrderByRelationAggregateInput = {
    _count?: SortOrder
  }

  export type AdminNotificationOrderByRelationAggregateInput = {
    _count?: SortOrder
  }

  export type PointTransactionOrderByRelationAggregateInput = {
    _count?: SortOrder
  }

  export type ReportCoReporterOrderByRelationAggregateInput = {
    _count?: SortOrder
  }

  export type UserSessionOrderByRelationAggregateInput = {
    _count?: SortOrder
  }

  export type UserCountOrderByAggregateInput = {
    id?: SortOrder
    createdAt?: SortOrder
    updatedAt?: SortOrder
    firstName?: SortOrder
    lastName?: SortOrder
    email?: SortOrder
    phoneNumber?: SortOrder
    passwordHash?: SortOrder
    role?: SortOrder
    status?: SortOrder
    isPhoneVerified?: SortOrder
    pointsBalance?: SortOrder
    totalPointsEarned?: SortOrder
    totalPointsSpent?: SortOrder
    lastActiveAt?: SortOrder
  }

  export type UserAvgOrderByAggregateInput = {
    pointsBalance?: SortOrder
    totalPointsEarned?: SortOrder
    totalPointsSpent?: SortOrder
  }

  export type UserMaxOrderByAggregateInput = {
    id?: SortOrder
    createdAt?: SortOrder
    updatedAt?: SortOrder
    firstName?: SortOrder
    lastName?: SortOrder
    email?: SortOrder
    phoneNumber?: SortOrder
    passwordHash?: SortOrder
    role?: SortOrder
    status?: SortOrder
    isPhoneVerified?: SortOrder
    pointsBalance?: SortOrder
    totalPointsEarned?: SortOrder
    totalPointsSpent?: SortOrder
    lastActiveAt?: SortOrder
  }

  export type UserMinOrderByAggregateInput = {
    id?: SortOrder
    createdAt?: SortOrder
    updatedAt?: SortOrder
    firstName?: SortOrder
    lastName?: SortOrder
    email?: SortOrder
    phoneNumber?: SortOrder
    passwordHash?: SortOrder
    role?: SortOrder
    status?: SortOrder
    isPhoneVerified?: SortOrder
    pointsBalance?: SortOrder
    totalPointsEarned?: SortOrder
    totalPointsSpent?: SortOrder
    lastActiveAt?: SortOrder
  }

  export type UserSumOrderByAggregateInput = {
    pointsBalance?: SortOrder
    totalPointsEarned?: SortOrder
    totalPointsSpent?: SortOrder
  }

  export type StringWithAggregatesFilter<$PrismaModel = never> = {
    equals?: string | StringFieldRefInput<$PrismaModel>
    in?: string[] | ListStringFieldRefInput<$PrismaModel>
    notIn?: string[] | ListStringFieldRefInput<$PrismaModel>
    lt?: string | StringFieldRefInput<$PrismaModel>
    lte?: string | StringFieldRefInput<$PrismaModel>
    gt?: string | StringFieldRefInput<$PrismaModel>
    gte?: string | StringFieldRefInput<$PrismaModel>
    contains?: string | StringFieldRefInput<$PrismaModel>
    startsWith?: string | StringFieldRefInput<$PrismaModel>
    endsWith?: string | StringFieldRefInput<$PrismaModel>
    mode?: QueryMode
    not?: NestedStringWithAggregatesFilter<$PrismaModel> | string
    _count?: NestedIntFilter<$PrismaModel>
    _min?: NestedStringFilter<$PrismaModel>
    _max?: NestedStringFilter<$PrismaModel>
  }

  export type DateTimeWithAggregatesFilter<$PrismaModel = never> = {
    equals?: Date | string | DateTimeFieldRefInput<$PrismaModel>
    in?: Date[] | string[] | ListDateTimeFieldRefInput<$PrismaModel>
    notIn?: Date[] | string[] | ListDateTimeFieldRefInput<$PrismaModel>
    lt?: Date | string | DateTimeFieldRefInput<$PrismaModel>
    lte?: Date | string | DateTimeFieldRefInput<$PrismaModel>
    gt?: Date | string | DateTimeFieldRefInput<$PrismaModel>
    gte?: Date | string | DateTimeFieldRefInput<$PrismaModel>
    not?: NestedDateTimeWithAggregatesFilter<$PrismaModel> | Date | string
    _count?: NestedIntFilter<$PrismaModel>
    _min?: NestedDateTimeFilter<$PrismaModel>
    _max?: NestedDateTimeFilter<$PrismaModel>
  }

  export type EnumRoleWithAggregatesFilter<$PrismaModel = never> = {
    equals?: $Enums.Role | EnumRoleFieldRefInput<$PrismaModel>
    in?: $Enums.Role[] | ListEnumRoleFieldRefInput<$PrismaModel>
    notIn?: $Enums.Role[] | ListEnumRoleFieldRefInput<$PrismaModel>
    not?: NestedEnumRoleWithAggregatesFilter<$PrismaModel> | $Enums.Role
    _count?: NestedIntFilter<$PrismaModel>
    _min?: NestedEnumRoleFilter<$PrismaModel>
    _max?: NestedEnumRoleFilter<$PrismaModel>
  }

  export type EnumUserStatusWithAggregatesFilter<$PrismaModel = never> = {
    equals?: $Enums.UserStatus | EnumUserStatusFieldRefInput<$PrismaModel>
    in?: $Enums.UserStatus[] | ListEnumUserStatusFieldRefInput<$PrismaModel>
    notIn?: $Enums.UserStatus[] | ListEnumUserStatusFieldRefInput<$PrismaModel>
    not?: NestedEnumUserStatusWithAggregatesFilter<$PrismaModel> | $Enums.UserStatus
    _count?: NestedIntFilter<$PrismaModel>
    _min?: NestedEnumUserStatusFilter<$PrismaModel>
    _max?: NestedEnumUserStatusFilter<$PrismaModel>
  }

  export type BoolWithAggregatesFilter<$PrismaModel = never> = {
    equals?: boolean | BooleanFieldRefInput<$PrismaModel>
    not?: NestedBoolWithAggregatesFilter<$PrismaModel> | boolean
    _count?: NestedIntFilter<$PrismaModel>
    _min?: NestedBoolFilter<$PrismaModel>
    _max?: NestedBoolFilter<$PrismaModel>
  }

  export type IntWithAggregatesFilter<$PrismaModel = never> = {
    equals?: number | IntFieldRefInput<$PrismaModel>
    in?: number[] | ListIntFieldRefInput<$PrismaModel>
    notIn?: number[] | ListIntFieldRefInput<$PrismaModel>
    lt?: number | IntFieldRefInput<$PrismaModel>
    lte?: number | IntFieldRefInput<$PrismaModel>
    gt?: number | IntFieldRefInput<$PrismaModel>
    gte?: number | IntFieldRefInput<$PrismaModel>
    not?: NestedIntWithAggregatesFilter<$PrismaModel> | number
    _count?: NestedIntFilter<$PrismaModel>
    _avg?: NestedFloatFilter<$PrismaModel>
    _sum?: NestedIntFilter<$PrismaModel>
    _min?: NestedIntFilter<$PrismaModel>
    _max?: NestedIntFilter<$PrismaModel>
  }

  export type DateTimeNullableWithAggregatesFilter<$PrismaModel = never> = {
    equals?: Date | string | DateTimeFieldRefInput<$PrismaModel> | null
    in?: Date[] | string[] | ListDateTimeFieldRefInput<$PrismaModel> | null
    notIn?: Date[] | string[] | ListDateTimeFieldRefInput<$PrismaModel> | null
    lt?: Date | string | DateTimeFieldRefInput<$PrismaModel>
    lte?: Date | string | DateTimeFieldRefInput<$PrismaModel>
    gt?: Date | string | DateTimeFieldRefInput<$PrismaModel>
    gte?: Date | string | DateTimeFieldRefInput<$PrismaModel>
    not?: NestedDateTimeNullableWithAggregatesFilter<$PrismaModel> | Date | string | null
    _count?: NestedIntNullableFilter<$PrismaModel>
    _min?: NestedDateTimeNullableFilter<$PrismaModel>
    _max?: NestedDateTimeNullableFilter<$PrismaModel>
  }

  export type StringNullableFilter<$PrismaModel = never> = {
    equals?: string | StringFieldRefInput<$PrismaModel> | null
    in?: string[] | ListStringFieldRefInput<$PrismaModel> | null
    notIn?: string[] | ListStringFieldRefInput<$PrismaModel> | null
    lt?: string | StringFieldRefInput<$PrismaModel>
    lte?: string | StringFieldRefInput<$PrismaModel>
    gt?: string | StringFieldRefInput<$PrismaModel>
    gte?: string | StringFieldRefInput<$PrismaModel>
    contains?: string | StringFieldRefInput<$PrismaModel>
    startsWith?: string | StringFieldRefInput<$PrismaModel>
    endsWith?: string | StringFieldRefInput<$PrismaModel>
    mode?: QueryMode
    not?: NestedStringNullableFilter<$PrismaModel> | string | null
  }

  export type UserScalarRelationFilter = {
    is?: UserWhereInput
    isNot?: UserWhereInput
  }

  export type UserSessionCountOrderByAggregateInput = {
    id?: SortOrder
    createdAt?: SortOrder
    userId?: SortOrder
    tokenId?: SortOrder
    refreshTokenHash?: SortOrder
    deviceInfo?: SortOrder
    ipAddress?: SortOrder
    expiresAt?: SortOrder
    revokedAt?: SortOrder
  }

  export type UserSessionMaxOrderByAggregateInput = {
    id?: SortOrder
    createdAt?: SortOrder
    userId?: SortOrder
    tokenId?: SortOrder
    refreshTokenHash?: SortOrder
    deviceInfo?: SortOrder
    ipAddress?: SortOrder
    expiresAt?: SortOrder
    revokedAt?: SortOrder
  }

  export type UserSessionMinOrderByAggregateInput = {
    id?: SortOrder
    createdAt?: SortOrder
    userId?: SortOrder
    tokenId?: SortOrder
    refreshTokenHash?: SortOrder
    deviceInfo?: SortOrder
    ipAddress?: SortOrder
    expiresAt?: SortOrder
    revokedAt?: SortOrder
  }

  export type StringNullableWithAggregatesFilter<$PrismaModel = never> = {
    equals?: string | StringFieldRefInput<$PrismaModel> | null
    in?: string[] | ListStringFieldRefInput<$PrismaModel> | null
    notIn?: string[] | ListStringFieldRefInput<$PrismaModel> | null
    lt?: string | StringFieldRefInput<$PrismaModel>
    lte?: string | StringFieldRefInput<$PrismaModel>
    gt?: string | StringFieldRefInput<$PrismaModel>
    gte?: string | StringFieldRefInput<$PrismaModel>
    contains?: string | StringFieldRefInput<$PrismaModel>
    startsWith?: string | StringFieldRefInput<$PrismaModel>
    endsWith?: string | StringFieldRefInput<$PrismaModel>
    mode?: QueryMode
    not?: NestedStringNullableWithAggregatesFilter<$PrismaModel> | string | null
    _count?: NestedIntNullableFilter<$PrismaModel>
    _min?: NestedStringNullableFilter<$PrismaModel>
    _max?: NestedStringNullableFilter<$PrismaModel>
  }

  export type PhoneOtpCountOrderByAggregateInput = {
    id?: SortOrder
    createdAt?: SortOrder
    phoneNumber?: SortOrder
    code?: SortOrder
    expiresAt?: SortOrder
    attemptCount?: SortOrder
  }

  export type PhoneOtpAvgOrderByAggregateInput = {
    attemptCount?: SortOrder
  }

  export type PhoneOtpMaxOrderByAggregateInput = {
    id?: SortOrder
    createdAt?: SortOrder
    phoneNumber?: SortOrder
    code?: SortOrder
    expiresAt?: SortOrder
    attemptCount?: SortOrder
  }

  export type PhoneOtpMinOrderByAggregateInput = {
    id?: SortOrder
    createdAt?: SortOrder
    phoneNumber?: SortOrder
    code?: SortOrder
    expiresAt?: SortOrder
    attemptCount?: SortOrder
  }

  export type PhoneOtpSumOrderByAggregateInput = {
    attemptCount?: SortOrder
  }

  export type LoginFailureCountOrderByAggregateInput = {
    id?: SortOrder
    phoneNumber?: SortOrder
    firstFailedAt?: SortOrder
    attemptCount?: SortOrder
  }

  export type LoginFailureAvgOrderByAggregateInput = {
    attemptCount?: SortOrder
  }

  export type LoginFailureMaxOrderByAggregateInput = {
    id?: SortOrder
    phoneNumber?: SortOrder
    firstFailedAt?: SortOrder
    attemptCount?: SortOrder
  }

  export type LoginFailureMinOrderByAggregateInput = {
    id?: SortOrder
    phoneNumber?: SortOrder
    firstFailedAt?: SortOrder
    attemptCount?: SortOrder
  }

  export type LoginFailureSumOrderByAggregateInput = {
    attemptCount?: SortOrder
  }

  export type EnumAdminNotificationToneFilter<$PrismaModel = never> = {
    equals?: $Enums.AdminNotificationTone | EnumAdminNotificationToneFieldRefInput<$PrismaModel>
    in?: $Enums.AdminNotificationTone[] | ListEnumAdminNotificationToneFieldRefInput<$PrismaModel>
    notIn?: $Enums.AdminNotificationTone[] | ListEnumAdminNotificationToneFieldRefInput<$PrismaModel>
    not?: NestedEnumAdminNotificationToneFilter<$PrismaModel> | $Enums.AdminNotificationTone
  }

  export type EnumAdminNotificationCategoryFilter<$PrismaModel = never> = {
    equals?: $Enums.AdminNotificationCategory | EnumAdminNotificationCategoryFieldRefInput<$PrismaModel>
    in?: $Enums.AdminNotificationCategory[] | ListEnumAdminNotificationCategoryFieldRefInput<$PrismaModel>
    notIn?: $Enums.AdminNotificationCategory[] | ListEnumAdminNotificationCategoryFieldRefInput<$PrismaModel>
    not?: NestedEnumAdminNotificationCategoryFilter<$PrismaModel> | $Enums.AdminNotificationCategory
  }

  export type UserNullableScalarRelationFilter = {
    is?: UserWhereInput | null
    isNot?: UserWhereInput | null
  }

  export type AdminNotificationCountOrderByAggregateInput = {
    id?: SortOrder
    createdAt?: SortOrder
    updatedAt?: SortOrder
    userId?: SortOrder
    title?: SortOrder
    message?: SortOrder
    timeLabel?: SortOrder
    tone?: SortOrder
    category?: SortOrder
    isUnread?: SortOrder
    href?: SortOrder
  }

  export type AdminNotificationMaxOrderByAggregateInput = {
    id?: SortOrder
    createdAt?: SortOrder
    updatedAt?: SortOrder
    userId?: SortOrder
    title?: SortOrder
    message?: SortOrder
    timeLabel?: SortOrder
    tone?: SortOrder
    category?: SortOrder
    isUnread?: SortOrder
    href?: SortOrder
  }

  export type AdminNotificationMinOrderByAggregateInput = {
    id?: SortOrder
    createdAt?: SortOrder
    updatedAt?: SortOrder
    userId?: SortOrder
    title?: SortOrder
    message?: SortOrder
    timeLabel?: SortOrder
    tone?: SortOrder
    category?: SortOrder
    isUnread?: SortOrder
    href?: SortOrder
  }

  export type EnumAdminNotificationToneWithAggregatesFilter<$PrismaModel = never> = {
    equals?: $Enums.AdminNotificationTone | EnumAdminNotificationToneFieldRefInput<$PrismaModel>
    in?: $Enums.AdminNotificationTone[] | ListEnumAdminNotificationToneFieldRefInput<$PrismaModel>
    notIn?: $Enums.AdminNotificationTone[] | ListEnumAdminNotificationToneFieldRefInput<$PrismaModel>
    not?: NestedEnumAdminNotificationToneWithAggregatesFilter<$PrismaModel> | $Enums.AdminNotificationTone
    _count?: NestedIntFilter<$PrismaModel>
    _min?: NestedEnumAdminNotificationToneFilter<$PrismaModel>
    _max?: NestedEnumAdminNotificationToneFilter<$PrismaModel>
  }

  export type EnumAdminNotificationCategoryWithAggregatesFilter<$PrismaModel = never> = {
    equals?: $Enums.AdminNotificationCategory | EnumAdminNotificationCategoryFieldRefInput<$PrismaModel>
    in?: $Enums.AdminNotificationCategory[] | ListEnumAdminNotificationCategoryFieldRefInput<$PrismaModel>
    notIn?: $Enums.AdminNotificationCategory[] | ListEnumAdminNotificationCategoryFieldRefInput<$PrismaModel>
    not?: NestedEnumAdminNotificationCategoryWithAggregatesFilter<$PrismaModel> | $Enums.AdminNotificationCategory
    _count?: NestedIntFilter<$PrismaModel>
    _min?: NestedEnumAdminNotificationCategoryFilter<$PrismaModel>
    _max?: NestedEnumAdminNotificationCategoryFilter<$PrismaModel>
  }
  export type JsonNullableFilter<$PrismaModel = never> =
    | PatchUndefined<
        Either<Required<JsonNullableFilterBase<$PrismaModel>>, Exclude<keyof Required<JsonNullableFilterBase<$PrismaModel>>, 'path'>>,
        Required<JsonNullableFilterBase<$PrismaModel>>
      >
    | OptionalFlat<Omit<Required<JsonNullableFilterBase<$PrismaModel>>, 'path'>>

  export type JsonNullableFilterBase<$PrismaModel = never> = {
    equals?: InputJsonValue | JsonFieldRefInput<$PrismaModel> | JsonNullValueFilter
    path?: string[]
    mode?: QueryMode | EnumQueryModeFieldRefInput<$PrismaModel>
    string_contains?: string | StringFieldRefInput<$PrismaModel>
    string_starts_with?: string | StringFieldRefInput<$PrismaModel>
    string_ends_with?: string | StringFieldRefInput<$PrismaModel>
    array_starts_with?: InputJsonValue | JsonFieldRefInput<$PrismaModel> | null
    array_ends_with?: InputJsonValue | JsonFieldRefInput<$PrismaModel> | null
    array_contains?: InputJsonValue | JsonFieldRefInput<$PrismaModel> | null
    lt?: InputJsonValue | JsonFieldRefInput<$PrismaModel>
    lte?: InputJsonValue | JsonFieldRefInput<$PrismaModel>
    gt?: InputJsonValue | JsonFieldRefInput<$PrismaModel>
    gte?: InputJsonValue | JsonFieldRefInput<$PrismaModel>
    not?: InputJsonValue | JsonFieldRefInput<$PrismaModel> | JsonNullValueFilter
  }

  export type PointTransactionCountOrderByAggregateInput = {
    id?: SortOrder
    createdAt?: SortOrder
    userId?: SortOrder
    delta?: SortOrder
    balanceAfter?: SortOrder
    reasonCode?: SortOrder
    referenceType?: SortOrder
    referenceId?: SortOrder
    metadata?: SortOrder
  }

  export type PointTransactionAvgOrderByAggregateInput = {
    delta?: SortOrder
    balanceAfter?: SortOrder
  }

  export type PointTransactionMaxOrderByAggregateInput = {
    id?: SortOrder
    createdAt?: SortOrder
    userId?: SortOrder
    delta?: SortOrder
    balanceAfter?: SortOrder
    reasonCode?: SortOrder
    referenceType?: SortOrder
    referenceId?: SortOrder
  }

  export type PointTransactionMinOrderByAggregateInput = {
    id?: SortOrder
    createdAt?: SortOrder
    userId?: SortOrder
    delta?: SortOrder
    balanceAfter?: SortOrder
    reasonCode?: SortOrder
    referenceType?: SortOrder
    referenceId?: SortOrder
  }

  export type PointTransactionSumOrderByAggregateInput = {
    delta?: SortOrder
    balanceAfter?: SortOrder
  }
  export type JsonNullableWithAggregatesFilter<$PrismaModel = never> =
    | PatchUndefined<
        Either<Required<JsonNullableWithAggregatesFilterBase<$PrismaModel>>, Exclude<keyof Required<JsonNullableWithAggregatesFilterBase<$PrismaModel>>, 'path'>>,
        Required<JsonNullableWithAggregatesFilterBase<$PrismaModel>>
      >
    | OptionalFlat<Omit<Required<JsonNullableWithAggregatesFilterBase<$PrismaModel>>, 'path'>>

  export type JsonNullableWithAggregatesFilterBase<$PrismaModel = never> = {
    equals?: InputJsonValue | JsonFieldRefInput<$PrismaModel> | JsonNullValueFilter
    path?: string[]
    mode?: QueryMode | EnumQueryModeFieldRefInput<$PrismaModel>
    string_contains?: string | StringFieldRefInput<$PrismaModel>
    string_starts_with?: string | StringFieldRefInput<$PrismaModel>
    string_ends_with?: string | StringFieldRefInput<$PrismaModel>
    array_starts_with?: InputJsonValue | JsonFieldRefInput<$PrismaModel> | null
    array_ends_with?: InputJsonValue | JsonFieldRefInput<$PrismaModel> | null
    array_contains?: InputJsonValue | JsonFieldRefInput<$PrismaModel> | null
    lt?: InputJsonValue | JsonFieldRefInput<$PrismaModel>
    lte?: InputJsonValue | JsonFieldRefInput<$PrismaModel>
    gt?: InputJsonValue | JsonFieldRefInput<$PrismaModel>
    gte?: InputJsonValue | JsonFieldRefInput<$PrismaModel>
    not?: InputJsonValue | JsonFieldRefInput<$PrismaModel> | JsonNullValueFilter
    _count?: NestedIntNullableFilter<$PrismaModel>
    _min?: NestedJsonNullableFilter<$PrismaModel>
    _max?: NestedJsonNullableFilter<$PrismaModel>
  }

  export type FloatFilter<$PrismaModel = never> = {
    equals?: number | FloatFieldRefInput<$PrismaModel>
    in?: number[] | ListFloatFieldRefInput<$PrismaModel>
    notIn?: number[] | ListFloatFieldRefInput<$PrismaModel>
    lt?: number | FloatFieldRefInput<$PrismaModel>
    lte?: number | FloatFieldRefInput<$PrismaModel>
    gt?: number | FloatFieldRefInput<$PrismaModel>
    gte?: number | FloatFieldRefInput<$PrismaModel>
    not?: NestedFloatFilter<$PrismaModel> | number
  }

  export type EnumSiteStatusFilter<$PrismaModel = never> = {
    equals?: $Enums.SiteStatus | EnumSiteStatusFieldRefInput<$PrismaModel>
    in?: $Enums.SiteStatus[] | ListEnumSiteStatusFieldRefInput<$PrismaModel>
    notIn?: $Enums.SiteStatus[] | ListEnumSiteStatusFieldRefInput<$PrismaModel>
    not?: NestedEnumSiteStatusFilter<$PrismaModel> | $Enums.SiteStatus
  }

  export type CleanupEventListRelationFilter = {
    every?: CleanupEventWhereInput
    some?: CleanupEventWhereInput
    none?: CleanupEventWhereInput
  }

  export type CleanupEventOrderByRelationAggregateInput = {
    _count?: SortOrder
  }

  export type SiteCountOrderByAggregateInput = {
    id?: SortOrder
    createdAt?: SortOrder
    updatedAt?: SortOrder
    latitude?: SortOrder
    longitude?: SortOrder
    description?: SortOrder
    status?: SortOrder
  }

  export type SiteAvgOrderByAggregateInput = {
    latitude?: SortOrder
    longitude?: SortOrder
  }

  export type SiteMaxOrderByAggregateInput = {
    id?: SortOrder
    createdAt?: SortOrder
    updatedAt?: SortOrder
    latitude?: SortOrder
    longitude?: SortOrder
    description?: SortOrder
    status?: SortOrder
  }

  export type SiteMinOrderByAggregateInput = {
    id?: SortOrder
    createdAt?: SortOrder
    updatedAt?: SortOrder
    latitude?: SortOrder
    longitude?: SortOrder
    description?: SortOrder
    status?: SortOrder
  }

  export type SiteSumOrderByAggregateInput = {
    latitude?: SortOrder
    longitude?: SortOrder
  }

  export type FloatWithAggregatesFilter<$PrismaModel = never> = {
    equals?: number | FloatFieldRefInput<$PrismaModel>
    in?: number[] | ListFloatFieldRefInput<$PrismaModel>
    notIn?: number[] | ListFloatFieldRefInput<$PrismaModel>
    lt?: number | FloatFieldRefInput<$PrismaModel>
    lte?: number | FloatFieldRefInput<$PrismaModel>
    gt?: number | FloatFieldRefInput<$PrismaModel>
    gte?: number | FloatFieldRefInput<$PrismaModel>
    not?: NestedFloatWithAggregatesFilter<$PrismaModel> | number
    _count?: NestedIntFilter<$PrismaModel>
    _avg?: NestedFloatFilter<$PrismaModel>
    _sum?: NestedFloatFilter<$PrismaModel>
    _min?: NestedFloatFilter<$PrismaModel>
    _max?: NestedFloatFilter<$PrismaModel>
  }

  export type EnumSiteStatusWithAggregatesFilter<$PrismaModel = never> = {
    equals?: $Enums.SiteStatus | EnumSiteStatusFieldRefInput<$PrismaModel>
    in?: $Enums.SiteStatus[] | ListEnumSiteStatusFieldRefInput<$PrismaModel>
    notIn?: $Enums.SiteStatus[] | ListEnumSiteStatusFieldRefInput<$PrismaModel>
    not?: NestedEnumSiteStatusWithAggregatesFilter<$PrismaModel> | $Enums.SiteStatus
    _count?: NestedIntFilter<$PrismaModel>
    _min?: NestedEnumSiteStatusFilter<$PrismaModel>
    _max?: NestedEnumSiteStatusFilter<$PrismaModel>
  }

  export type StringNullableListFilter<$PrismaModel = never> = {
    equals?: string[] | ListStringFieldRefInput<$PrismaModel> | null
    has?: string | StringFieldRefInput<$PrismaModel> | null
    hasEvery?: string[] | ListStringFieldRefInput<$PrismaModel>
    hasSome?: string[] | ListStringFieldRefInput<$PrismaModel>
    isEmpty?: boolean
  }

  export type IntNullableFilter<$PrismaModel = never> = {
    equals?: number | IntFieldRefInput<$PrismaModel> | null
    in?: number[] | ListIntFieldRefInput<$PrismaModel> | null
    notIn?: number[] | ListIntFieldRefInput<$PrismaModel> | null
    lt?: number | IntFieldRefInput<$PrismaModel>
    lte?: number | IntFieldRefInput<$PrismaModel>
    gt?: number | IntFieldRefInput<$PrismaModel>
    gte?: number | IntFieldRefInput<$PrismaModel>
    not?: NestedIntNullableFilter<$PrismaModel> | number | null
  }

  export type EnumReportStatusFilter<$PrismaModel = never> = {
    equals?: $Enums.ReportStatus | EnumReportStatusFieldRefInput<$PrismaModel>
    in?: $Enums.ReportStatus[] | ListEnumReportStatusFieldRefInput<$PrismaModel>
    notIn?: $Enums.ReportStatus[] | ListEnumReportStatusFieldRefInput<$PrismaModel>
    not?: NestedEnumReportStatusFilter<$PrismaModel> | $Enums.ReportStatus
  }

  export type SiteScalarRelationFilter = {
    is?: SiteWhereInput
    isNot?: SiteWhereInput
  }

  export type ReportNullableScalarRelationFilter = {
    is?: ReportWhereInput | null
    isNot?: ReportWhereInput | null
  }

  export type ReportCountOrderByAggregateInput = {
    id?: SortOrder
    createdAt?: SortOrder
    reportNumber?: SortOrder
    siteId?: SortOrder
    reporterId?: SortOrder
    description?: SortOrder
    mediaUrls?: SortOrder
    category?: SortOrder
    severity?: SortOrder
    status?: SortOrder
    moderatedAt?: SortOrder
    moderationReason?: SortOrder
    moderatedById?: SortOrder
    potentialDuplicateOfId?: SortOrder
  }

  export type ReportAvgOrderByAggregateInput = {
    severity?: SortOrder
  }

  export type ReportMaxOrderByAggregateInput = {
    id?: SortOrder
    createdAt?: SortOrder
    reportNumber?: SortOrder
    siteId?: SortOrder
    reporterId?: SortOrder
    description?: SortOrder
    category?: SortOrder
    severity?: SortOrder
    status?: SortOrder
    moderatedAt?: SortOrder
    moderationReason?: SortOrder
    moderatedById?: SortOrder
    potentialDuplicateOfId?: SortOrder
  }

  export type ReportMinOrderByAggregateInput = {
    id?: SortOrder
    createdAt?: SortOrder
    reportNumber?: SortOrder
    siteId?: SortOrder
    reporterId?: SortOrder
    description?: SortOrder
    category?: SortOrder
    severity?: SortOrder
    status?: SortOrder
    moderatedAt?: SortOrder
    moderationReason?: SortOrder
    moderatedById?: SortOrder
    potentialDuplicateOfId?: SortOrder
  }

  export type ReportSumOrderByAggregateInput = {
    severity?: SortOrder
  }

  export type IntNullableWithAggregatesFilter<$PrismaModel = never> = {
    equals?: number | IntFieldRefInput<$PrismaModel> | null
    in?: number[] | ListIntFieldRefInput<$PrismaModel> | null
    notIn?: number[] | ListIntFieldRefInput<$PrismaModel> | null
    lt?: number | IntFieldRefInput<$PrismaModel>
    lte?: number | IntFieldRefInput<$PrismaModel>
    gt?: number | IntFieldRefInput<$PrismaModel>
    gte?: number | IntFieldRefInput<$PrismaModel>
    not?: NestedIntNullableWithAggregatesFilter<$PrismaModel> | number | null
    _count?: NestedIntNullableFilter<$PrismaModel>
    _avg?: NestedFloatNullableFilter<$PrismaModel>
    _sum?: NestedIntNullableFilter<$PrismaModel>
    _min?: NestedIntNullableFilter<$PrismaModel>
    _max?: NestedIntNullableFilter<$PrismaModel>
  }

  export type EnumReportStatusWithAggregatesFilter<$PrismaModel = never> = {
    equals?: $Enums.ReportStatus | EnumReportStatusFieldRefInput<$PrismaModel>
    in?: $Enums.ReportStatus[] | ListEnumReportStatusFieldRefInput<$PrismaModel>
    notIn?: $Enums.ReportStatus[] | ListEnumReportStatusFieldRefInput<$PrismaModel>
    not?: NestedEnumReportStatusWithAggregatesFilter<$PrismaModel> | $Enums.ReportStatus
    _count?: NestedIntFilter<$PrismaModel>
    _min?: NestedEnumReportStatusFilter<$PrismaModel>
    _max?: NestedEnumReportStatusFilter<$PrismaModel>
  }

  export type ReportScalarRelationFilter = {
    is?: ReportWhereInput
    isNot?: ReportWhereInput
  }

  export type ReportCoReporterReportIdUserIdCompoundUniqueInput = {
    reportId: string
    userId: string
  }

  export type ReportCoReporterCountOrderByAggregateInput = {
    id?: SortOrder
    createdAt?: SortOrder
    reportId?: SortOrder
    userId?: SortOrder
  }

  export type ReportCoReporterMaxOrderByAggregateInput = {
    id?: SortOrder
    createdAt?: SortOrder
    reportId?: SortOrder
    userId?: SortOrder
  }

  export type ReportCoReporterMinOrderByAggregateInput = {
    id?: SortOrder
    createdAt?: SortOrder
    reportId?: SortOrder
    userId?: SortOrder
  }

  export type CleanupEventCountOrderByAggregateInput = {
    id?: SortOrder
    createdAt?: SortOrder
    updatedAt?: SortOrder
    siteId?: SortOrder
    scheduledAt?: SortOrder
    completedAt?: SortOrder
    organizerId?: SortOrder
    participantCount?: SortOrder
  }

  export type CleanupEventAvgOrderByAggregateInput = {
    participantCount?: SortOrder
  }

  export type CleanupEventMaxOrderByAggregateInput = {
    id?: SortOrder
    createdAt?: SortOrder
    updatedAt?: SortOrder
    siteId?: SortOrder
    scheduledAt?: SortOrder
    completedAt?: SortOrder
    organizerId?: SortOrder
    participantCount?: SortOrder
  }

  export type CleanupEventMinOrderByAggregateInput = {
    id?: SortOrder
    createdAt?: SortOrder
    updatedAt?: SortOrder
    siteId?: SortOrder
    scheduledAt?: SortOrder
    completedAt?: SortOrder
    organizerId?: SortOrder
    participantCount?: SortOrder
  }

  export type CleanupEventSumOrderByAggregateInput = {
    participantCount?: SortOrder
  }

  export type ReportCreateNestedManyWithoutReporterInput = {
    create?: XOR<ReportCreateWithoutReporterInput, ReportUncheckedCreateWithoutReporterInput> | ReportCreateWithoutReporterInput[] | ReportUncheckedCreateWithoutReporterInput[]
    connectOrCreate?: ReportCreateOrConnectWithoutReporterInput | ReportCreateOrConnectWithoutReporterInput[]
    createMany?: ReportCreateManyReporterInputEnvelope
    connect?: ReportWhereUniqueInput | ReportWhereUniqueInput[]
  }

  export type ReportCreateNestedManyWithoutModeratedByInput = {
    create?: XOR<ReportCreateWithoutModeratedByInput, ReportUncheckedCreateWithoutModeratedByInput> | ReportCreateWithoutModeratedByInput[] | ReportUncheckedCreateWithoutModeratedByInput[]
    connectOrCreate?: ReportCreateOrConnectWithoutModeratedByInput | ReportCreateOrConnectWithoutModeratedByInput[]
    createMany?: ReportCreateManyModeratedByInputEnvelope
    connect?: ReportWhereUniqueInput | ReportWhereUniqueInput[]
  }

  export type AdminNotificationCreateNestedManyWithoutUserInput = {
    create?: XOR<AdminNotificationCreateWithoutUserInput, AdminNotificationUncheckedCreateWithoutUserInput> | AdminNotificationCreateWithoutUserInput[] | AdminNotificationUncheckedCreateWithoutUserInput[]
    connectOrCreate?: AdminNotificationCreateOrConnectWithoutUserInput | AdminNotificationCreateOrConnectWithoutUserInput[]
    createMany?: AdminNotificationCreateManyUserInputEnvelope
    connect?: AdminNotificationWhereUniqueInput | AdminNotificationWhereUniqueInput[]
  }

  export type PointTransactionCreateNestedManyWithoutUserInput = {
    create?: XOR<PointTransactionCreateWithoutUserInput, PointTransactionUncheckedCreateWithoutUserInput> | PointTransactionCreateWithoutUserInput[] | PointTransactionUncheckedCreateWithoutUserInput[]
    connectOrCreate?: PointTransactionCreateOrConnectWithoutUserInput | PointTransactionCreateOrConnectWithoutUserInput[]
    createMany?: PointTransactionCreateManyUserInputEnvelope
    connect?: PointTransactionWhereUniqueInput | PointTransactionWhereUniqueInput[]
  }

  export type ReportCoReporterCreateNestedManyWithoutUserInput = {
    create?: XOR<ReportCoReporterCreateWithoutUserInput, ReportCoReporterUncheckedCreateWithoutUserInput> | ReportCoReporterCreateWithoutUserInput[] | ReportCoReporterUncheckedCreateWithoutUserInput[]
    connectOrCreate?: ReportCoReporterCreateOrConnectWithoutUserInput | ReportCoReporterCreateOrConnectWithoutUserInput[]
    createMany?: ReportCoReporterCreateManyUserInputEnvelope
    connect?: ReportCoReporterWhereUniqueInput | ReportCoReporterWhereUniqueInput[]
  }

  export type UserSessionCreateNestedManyWithoutUserInput = {
    create?: XOR<UserSessionCreateWithoutUserInput, UserSessionUncheckedCreateWithoutUserInput> | UserSessionCreateWithoutUserInput[] | UserSessionUncheckedCreateWithoutUserInput[]
    connectOrCreate?: UserSessionCreateOrConnectWithoutUserInput | UserSessionCreateOrConnectWithoutUserInput[]
    createMany?: UserSessionCreateManyUserInputEnvelope
    connect?: UserSessionWhereUniqueInput | UserSessionWhereUniqueInput[]
  }

  export type ReportUncheckedCreateNestedManyWithoutReporterInput = {
    create?: XOR<ReportCreateWithoutReporterInput, ReportUncheckedCreateWithoutReporterInput> | ReportCreateWithoutReporterInput[] | ReportUncheckedCreateWithoutReporterInput[]
    connectOrCreate?: ReportCreateOrConnectWithoutReporterInput | ReportCreateOrConnectWithoutReporterInput[]
    createMany?: ReportCreateManyReporterInputEnvelope
    connect?: ReportWhereUniqueInput | ReportWhereUniqueInput[]
  }

  export type ReportUncheckedCreateNestedManyWithoutModeratedByInput = {
    create?: XOR<ReportCreateWithoutModeratedByInput, ReportUncheckedCreateWithoutModeratedByInput> | ReportCreateWithoutModeratedByInput[] | ReportUncheckedCreateWithoutModeratedByInput[]
    connectOrCreate?: ReportCreateOrConnectWithoutModeratedByInput | ReportCreateOrConnectWithoutModeratedByInput[]
    createMany?: ReportCreateManyModeratedByInputEnvelope
    connect?: ReportWhereUniqueInput | ReportWhereUniqueInput[]
  }

  export type AdminNotificationUncheckedCreateNestedManyWithoutUserInput = {
    create?: XOR<AdminNotificationCreateWithoutUserInput, AdminNotificationUncheckedCreateWithoutUserInput> | AdminNotificationCreateWithoutUserInput[] | AdminNotificationUncheckedCreateWithoutUserInput[]
    connectOrCreate?: AdminNotificationCreateOrConnectWithoutUserInput | AdminNotificationCreateOrConnectWithoutUserInput[]
    createMany?: AdminNotificationCreateManyUserInputEnvelope
    connect?: AdminNotificationWhereUniqueInput | AdminNotificationWhereUniqueInput[]
  }

  export type PointTransactionUncheckedCreateNestedManyWithoutUserInput = {
    create?: XOR<PointTransactionCreateWithoutUserInput, PointTransactionUncheckedCreateWithoutUserInput> | PointTransactionCreateWithoutUserInput[] | PointTransactionUncheckedCreateWithoutUserInput[]
    connectOrCreate?: PointTransactionCreateOrConnectWithoutUserInput | PointTransactionCreateOrConnectWithoutUserInput[]
    createMany?: PointTransactionCreateManyUserInputEnvelope
    connect?: PointTransactionWhereUniqueInput | PointTransactionWhereUniqueInput[]
  }

  export type ReportCoReporterUncheckedCreateNestedManyWithoutUserInput = {
    create?: XOR<ReportCoReporterCreateWithoutUserInput, ReportCoReporterUncheckedCreateWithoutUserInput> | ReportCoReporterCreateWithoutUserInput[] | ReportCoReporterUncheckedCreateWithoutUserInput[]
    connectOrCreate?: ReportCoReporterCreateOrConnectWithoutUserInput | ReportCoReporterCreateOrConnectWithoutUserInput[]
    createMany?: ReportCoReporterCreateManyUserInputEnvelope
    connect?: ReportCoReporterWhereUniqueInput | ReportCoReporterWhereUniqueInput[]
  }

  export type UserSessionUncheckedCreateNestedManyWithoutUserInput = {
    create?: XOR<UserSessionCreateWithoutUserInput, UserSessionUncheckedCreateWithoutUserInput> | UserSessionCreateWithoutUserInput[] | UserSessionUncheckedCreateWithoutUserInput[]
    connectOrCreate?: UserSessionCreateOrConnectWithoutUserInput | UserSessionCreateOrConnectWithoutUserInput[]
    createMany?: UserSessionCreateManyUserInputEnvelope
    connect?: UserSessionWhereUniqueInput | UserSessionWhereUniqueInput[]
  }

  export type StringFieldUpdateOperationsInput = {
    set?: string
  }

  export type DateTimeFieldUpdateOperationsInput = {
    set?: Date | string
  }

  export type EnumRoleFieldUpdateOperationsInput = {
    set?: $Enums.Role
  }

  export type EnumUserStatusFieldUpdateOperationsInput = {
    set?: $Enums.UserStatus
  }

  export type BoolFieldUpdateOperationsInput = {
    set?: boolean
  }

  export type IntFieldUpdateOperationsInput = {
    set?: number
    increment?: number
    decrement?: number
    multiply?: number
    divide?: number
  }

  export type NullableDateTimeFieldUpdateOperationsInput = {
    set?: Date | string | null
  }

  export type ReportUpdateManyWithoutReporterNestedInput = {
    create?: XOR<ReportCreateWithoutReporterInput, ReportUncheckedCreateWithoutReporterInput> | ReportCreateWithoutReporterInput[] | ReportUncheckedCreateWithoutReporterInput[]
    connectOrCreate?: ReportCreateOrConnectWithoutReporterInput | ReportCreateOrConnectWithoutReporterInput[]
    upsert?: ReportUpsertWithWhereUniqueWithoutReporterInput | ReportUpsertWithWhereUniqueWithoutReporterInput[]
    createMany?: ReportCreateManyReporterInputEnvelope
    set?: ReportWhereUniqueInput | ReportWhereUniqueInput[]
    disconnect?: ReportWhereUniqueInput | ReportWhereUniqueInput[]
    delete?: ReportWhereUniqueInput | ReportWhereUniqueInput[]
    connect?: ReportWhereUniqueInput | ReportWhereUniqueInput[]
    update?: ReportUpdateWithWhereUniqueWithoutReporterInput | ReportUpdateWithWhereUniqueWithoutReporterInput[]
    updateMany?: ReportUpdateManyWithWhereWithoutReporterInput | ReportUpdateManyWithWhereWithoutReporterInput[]
    deleteMany?: ReportScalarWhereInput | ReportScalarWhereInput[]
  }

  export type ReportUpdateManyWithoutModeratedByNestedInput = {
    create?: XOR<ReportCreateWithoutModeratedByInput, ReportUncheckedCreateWithoutModeratedByInput> | ReportCreateWithoutModeratedByInput[] | ReportUncheckedCreateWithoutModeratedByInput[]
    connectOrCreate?: ReportCreateOrConnectWithoutModeratedByInput | ReportCreateOrConnectWithoutModeratedByInput[]
    upsert?: ReportUpsertWithWhereUniqueWithoutModeratedByInput | ReportUpsertWithWhereUniqueWithoutModeratedByInput[]
    createMany?: ReportCreateManyModeratedByInputEnvelope
    set?: ReportWhereUniqueInput | ReportWhereUniqueInput[]
    disconnect?: ReportWhereUniqueInput | ReportWhereUniqueInput[]
    delete?: ReportWhereUniqueInput | ReportWhereUniqueInput[]
    connect?: ReportWhereUniqueInput | ReportWhereUniqueInput[]
    update?: ReportUpdateWithWhereUniqueWithoutModeratedByInput | ReportUpdateWithWhereUniqueWithoutModeratedByInput[]
    updateMany?: ReportUpdateManyWithWhereWithoutModeratedByInput | ReportUpdateManyWithWhereWithoutModeratedByInput[]
    deleteMany?: ReportScalarWhereInput | ReportScalarWhereInput[]
  }

  export type AdminNotificationUpdateManyWithoutUserNestedInput = {
    create?: XOR<AdminNotificationCreateWithoutUserInput, AdminNotificationUncheckedCreateWithoutUserInput> | AdminNotificationCreateWithoutUserInput[] | AdminNotificationUncheckedCreateWithoutUserInput[]
    connectOrCreate?: AdminNotificationCreateOrConnectWithoutUserInput | AdminNotificationCreateOrConnectWithoutUserInput[]
    upsert?: AdminNotificationUpsertWithWhereUniqueWithoutUserInput | AdminNotificationUpsertWithWhereUniqueWithoutUserInput[]
    createMany?: AdminNotificationCreateManyUserInputEnvelope
    set?: AdminNotificationWhereUniqueInput | AdminNotificationWhereUniqueInput[]
    disconnect?: AdminNotificationWhereUniqueInput | AdminNotificationWhereUniqueInput[]
    delete?: AdminNotificationWhereUniqueInput | AdminNotificationWhereUniqueInput[]
    connect?: AdminNotificationWhereUniqueInput | AdminNotificationWhereUniqueInput[]
    update?: AdminNotificationUpdateWithWhereUniqueWithoutUserInput | AdminNotificationUpdateWithWhereUniqueWithoutUserInput[]
    updateMany?: AdminNotificationUpdateManyWithWhereWithoutUserInput | AdminNotificationUpdateManyWithWhereWithoutUserInput[]
    deleteMany?: AdminNotificationScalarWhereInput | AdminNotificationScalarWhereInput[]
  }

  export type PointTransactionUpdateManyWithoutUserNestedInput = {
    create?: XOR<PointTransactionCreateWithoutUserInput, PointTransactionUncheckedCreateWithoutUserInput> | PointTransactionCreateWithoutUserInput[] | PointTransactionUncheckedCreateWithoutUserInput[]
    connectOrCreate?: PointTransactionCreateOrConnectWithoutUserInput | PointTransactionCreateOrConnectWithoutUserInput[]
    upsert?: PointTransactionUpsertWithWhereUniqueWithoutUserInput | PointTransactionUpsertWithWhereUniqueWithoutUserInput[]
    createMany?: PointTransactionCreateManyUserInputEnvelope
    set?: PointTransactionWhereUniqueInput | PointTransactionWhereUniqueInput[]
    disconnect?: PointTransactionWhereUniqueInput | PointTransactionWhereUniqueInput[]
    delete?: PointTransactionWhereUniqueInput | PointTransactionWhereUniqueInput[]
    connect?: PointTransactionWhereUniqueInput | PointTransactionWhereUniqueInput[]
    update?: PointTransactionUpdateWithWhereUniqueWithoutUserInput | PointTransactionUpdateWithWhereUniqueWithoutUserInput[]
    updateMany?: PointTransactionUpdateManyWithWhereWithoutUserInput | PointTransactionUpdateManyWithWhereWithoutUserInput[]
    deleteMany?: PointTransactionScalarWhereInput | PointTransactionScalarWhereInput[]
  }

  export type ReportCoReporterUpdateManyWithoutUserNestedInput = {
    create?: XOR<ReportCoReporterCreateWithoutUserInput, ReportCoReporterUncheckedCreateWithoutUserInput> | ReportCoReporterCreateWithoutUserInput[] | ReportCoReporterUncheckedCreateWithoutUserInput[]
    connectOrCreate?: ReportCoReporterCreateOrConnectWithoutUserInput | ReportCoReporterCreateOrConnectWithoutUserInput[]
    upsert?: ReportCoReporterUpsertWithWhereUniqueWithoutUserInput | ReportCoReporterUpsertWithWhereUniqueWithoutUserInput[]
    createMany?: ReportCoReporterCreateManyUserInputEnvelope
    set?: ReportCoReporterWhereUniqueInput | ReportCoReporterWhereUniqueInput[]
    disconnect?: ReportCoReporterWhereUniqueInput | ReportCoReporterWhereUniqueInput[]
    delete?: ReportCoReporterWhereUniqueInput | ReportCoReporterWhereUniqueInput[]
    connect?: ReportCoReporterWhereUniqueInput | ReportCoReporterWhereUniqueInput[]
    update?: ReportCoReporterUpdateWithWhereUniqueWithoutUserInput | ReportCoReporterUpdateWithWhereUniqueWithoutUserInput[]
    updateMany?: ReportCoReporterUpdateManyWithWhereWithoutUserInput | ReportCoReporterUpdateManyWithWhereWithoutUserInput[]
    deleteMany?: ReportCoReporterScalarWhereInput | ReportCoReporterScalarWhereInput[]
  }

  export type UserSessionUpdateManyWithoutUserNestedInput = {
    create?: XOR<UserSessionCreateWithoutUserInput, UserSessionUncheckedCreateWithoutUserInput> | UserSessionCreateWithoutUserInput[] | UserSessionUncheckedCreateWithoutUserInput[]
    connectOrCreate?: UserSessionCreateOrConnectWithoutUserInput | UserSessionCreateOrConnectWithoutUserInput[]
    upsert?: UserSessionUpsertWithWhereUniqueWithoutUserInput | UserSessionUpsertWithWhereUniqueWithoutUserInput[]
    createMany?: UserSessionCreateManyUserInputEnvelope
    set?: UserSessionWhereUniqueInput | UserSessionWhereUniqueInput[]
    disconnect?: UserSessionWhereUniqueInput | UserSessionWhereUniqueInput[]
    delete?: UserSessionWhereUniqueInput | UserSessionWhereUniqueInput[]
    connect?: UserSessionWhereUniqueInput | UserSessionWhereUniqueInput[]
    update?: UserSessionUpdateWithWhereUniqueWithoutUserInput | UserSessionUpdateWithWhereUniqueWithoutUserInput[]
    updateMany?: UserSessionUpdateManyWithWhereWithoutUserInput | UserSessionUpdateManyWithWhereWithoutUserInput[]
    deleteMany?: UserSessionScalarWhereInput | UserSessionScalarWhereInput[]
  }

  export type ReportUncheckedUpdateManyWithoutReporterNestedInput = {
    create?: XOR<ReportCreateWithoutReporterInput, ReportUncheckedCreateWithoutReporterInput> | ReportCreateWithoutReporterInput[] | ReportUncheckedCreateWithoutReporterInput[]
    connectOrCreate?: ReportCreateOrConnectWithoutReporterInput | ReportCreateOrConnectWithoutReporterInput[]
    upsert?: ReportUpsertWithWhereUniqueWithoutReporterInput | ReportUpsertWithWhereUniqueWithoutReporterInput[]
    createMany?: ReportCreateManyReporterInputEnvelope
    set?: ReportWhereUniqueInput | ReportWhereUniqueInput[]
    disconnect?: ReportWhereUniqueInput | ReportWhereUniqueInput[]
    delete?: ReportWhereUniqueInput | ReportWhereUniqueInput[]
    connect?: ReportWhereUniqueInput | ReportWhereUniqueInput[]
    update?: ReportUpdateWithWhereUniqueWithoutReporterInput | ReportUpdateWithWhereUniqueWithoutReporterInput[]
    updateMany?: ReportUpdateManyWithWhereWithoutReporterInput | ReportUpdateManyWithWhereWithoutReporterInput[]
    deleteMany?: ReportScalarWhereInput | ReportScalarWhereInput[]
  }

  export type ReportUncheckedUpdateManyWithoutModeratedByNestedInput = {
    create?: XOR<ReportCreateWithoutModeratedByInput, ReportUncheckedCreateWithoutModeratedByInput> | ReportCreateWithoutModeratedByInput[] | ReportUncheckedCreateWithoutModeratedByInput[]
    connectOrCreate?: ReportCreateOrConnectWithoutModeratedByInput | ReportCreateOrConnectWithoutModeratedByInput[]
    upsert?: ReportUpsertWithWhereUniqueWithoutModeratedByInput | ReportUpsertWithWhereUniqueWithoutModeratedByInput[]
    createMany?: ReportCreateManyModeratedByInputEnvelope
    set?: ReportWhereUniqueInput | ReportWhereUniqueInput[]
    disconnect?: ReportWhereUniqueInput | ReportWhereUniqueInput[]
    delete?: ReportWhereUniqueInput | ReportWhereUniqueInput[]
    connect?: ReportWhereUniqueInput | ReportWhereUniqueInput[]
    update?: ReportUpdateWithWhereUniqueWithoutModeratedByInput | ReportUpdateWithWhereUniqueWithoutModeratedByInput[]
    updateMany?: ReportUpdateManyWithWhereWithoutModeratedByInput | ReportUpdateManyWithWhereWithoutModeratedByInput[]
    deleteMany?: ReportScalarWhereInput | ReportScalarWhereInput[]
  }

  export type AdminNotificationUncheckedUpdateManyWithoutUserNestedInput = {
    create?: XOR<AdminNotificationCreateWithoutUserInput, AdminNotificationUncheckedCreateWithoutUserInput> | AdminNotificationCreateWithoutUserInput[] | AdminNotificationUncheckedCreateWithoutUserInput[]
    connectOrCreate?: AdminNotificationCreateOrConnectWithoutUserInput | AdminNotificationCreateOrConnectWithoutUserInput[]
    upsert?: AdminNotificationUpsertWithWhereUniqueWithoutUserInput | AdminNotificationUpsertWithWhereUniqueWithoutUserInput[]
    createMany?: AdminNotificationCreateManyUserInputEnvelope
    set?: AdminNotificationWhereUniqueInput | AdminNotificationWhereUniqueInput[]
    disconnect?: AdminNotificationWhereUniqueInput | AdminNotificationWhereUniqueInput[]
    delete?: AdminNotificationWhereUniqueInput | AdminNotificationWhereUniqueInput[]
    connect?: AdminNotificationWhereUniqueInput | AdminNotificationWhereUniqueInput[]
    update?: AdminNotificationUpdateWithWhereUniqueWithoutUserInput | AdminNotificationUpdateWithWhereUniqueWithoutUserInput[]
    updateMany?: AdminNotificationUpdateManyWithWhereWithoutUserInput | AdminNotificationUpdateManyWithWhereWithoutUserInput[]
    deleteMany?: AdminNotificationScalarWhereInput | AdminNotificationScalarWhereInput[]
  }

  export type PointTransactionUncheckedUpdateManyWithoutUserNestedInput = {
    create?: XOR<PointTransactionCreateWithoutUserInput, PointTransactionUncheckedCreateWithoutUserInput> | PointTransactionCreateWithoutUserInput[] | PointTransactionUncheckedCreateWithoutUserInput[]
    connectOrCreate?: PointTransactionCreateOrConnectWithoutUserInput | PointTransactionCreateOrConnectWithoutUserInput[]
    upsert?: PointTransactionUpsertWithWhereUniqueWithoutUserInput | PointTransactionUpsertWithWhereUniqueWithoutUserInput[]
    createMany?: PointTransactionCreateManyUserInputEnvelope
    set?: PointTransactionWhereUniqueInput | PointTransactionWhereUniqueInput[]
    disconnect?: PointTransactionWhereUniqueInput | PointTransactionWhereUniqueInput[]
    delete?: PointTransactionWhereUniqueInput | PointTransactionWhereUniqueInput[]
    connect?: PointTransactionWhereUniqueInput | PointTransactionWhereUniqueInput[]
    update?: PointTransactionUpdateWithWhereUniqueWithoutUserInput | PointTransactionUpdateWithWhereUniqueWithoutUserInput[]
    updateMany?: PointTransactionUpdateManyWithWhereWithoutUserInput | PointTransactionUpdateManyWithWhereWithoutUserInput[]
    deleteMany?: PointTransactionScalarWhereInput | PointTransactionScalarWhereInput[]
  }

  export type ReportCoReporterUncheckedUpdateManyWithoutUserNestedInput = {
    create?: XOR<ReportCoReporterCreateWithoutUserInput, ReportCoReporterUncheckedCreateWithoutUserInput> | ReportCoReporterCreateWithoutUserInput[] | ReportCoReporterUncheckedCreateWithoutUserInput[]
    connectOrCreate?: ReportCoReporterCreateOrConnectWithoutUserInput | ReportCoReporterCreateOrConnectWithoutUserInput[]
    upsert?: ReportCoReporterUpsertWithWhereUniqueWithoutUserInput | ReportCoReporterUpsertWithWhereUniqueWithoutUserInput[]
    createMany?: ReportCoReporterCreateManyUserInputEnvelope
    set?: ReportCoReporterWhereUniqueInput | ReportCoReporterWhereUniqueInput[]
    disconnect?: ReportCoReporterWhereUniqueInput | ReportCoReporterWhereUniqueInput[]
    delete?: ReportCoReporterWhereUniqueInput | ReportCoReporterWhereUniqueInput[]
    connect?: ReportCoReporterWhereUniqueInput | ReportCoReporterWhereUniqueInput[]
    update?: ReportCoReporterUpdateWithWhereUniqueWithoutUserInput | ReportCoReporterUpdateWithWhereUniqueWithoutUserInput[]
    updateMany?: ReportCoReporterUpdateManyWithWhereWithoutUserInput | ReportCoReporterUpdateManyWithWhereWithoutUserInput[]
    deleteMany?: ReportCoReporterScalarWhereInput | ReportCoReporterScalarWhereInput[]
  }

  export type UserSessionUncheckedUpdateManyWithoutUserNestedInput = {
    create?: XOR<UserSessionCreateWithoutUserInput, UserSessionUncheckedCreateWithoutUserInput> | UserSessionCreateWithoutUserInput[] | UserSessionUncheckedCreateWithoutUserInput[]
    connectOrCreate?: UserSessionCreateOrConnectWithoutUserInput | UserSessionCreateOrConnectWithoutUserInput[]
    upsert?: UserSessionUpsertWithWhereUniqueWithoutUserInput | UserSessionUpsertWithWhereUniqueWithoutUserInput[]
    createMany?: UserSessionCreateManyUserInputEnvelope
    set?: UserSessionWhereUniqueInput | UserSessionWhereUniqueInput[]
    disconnect?: UserSessionWhereUniqueInput | UserSessionWhereUniqueInput[]
    delete?: UserSessionWhereUniqueInput | UserSessionWhereUniqueInput[]
    connect?: UserSessionWhereUniqueInput | UserSessionWhereUniqueInput[]
    update?: UserSessionUpdateWithWhereUniqueWithoutUserInput | UserSessionUpdateWithWhereUniqueWithoutUserInput[]
    updateMany?: UserSessionUpdateManyWithWhereWithoutUserInput | UserSessionUpdateManyWithWhereWithoutUserInput[]
    deleteMany?: UserSessionScalarWhereInput | UserSessionScalarWhereInput[]
  }

  export type UserCreateNestedOneWithoutSessionsInput = {
    create?: XOR<UserCreateWithoutSessionsInput, UserUncheckedCreateWithoutSessionsInput>
    connectOrCreate?: UserCreateOrConnectWithoutSessionsInput
    connect?: UserWhereUniqueInput
  }

  export type NullableStringFieldUpdateOperationsInput = {
    set?: string | null
  }

  export type UserUpdateOneRequiredWithoutSessionsNestedInput = {
    create?: XOR<UserCreateWithoutSessionsInput, UserUncheckedCreateWithoutSessionsInput>
    connectOrCreate?: UserCreateOrConnectWithoutSessionsInput
    upsert?: UserUpsertWithoutSessionsInput
    connect?: UserWhereUniqueInput
    update?: XOR<XOR<UserUpdateToOneWithWhereWithoutSessionsInput, UserUpdateWithoutSessionsInput>, UserUncheckedUpdateWithoutSessionsInput>
  }

  export type UserCreateNestedOneWithoutAdminNotificationsInput = {
    create?: XOR<UserCreateWithoutAdminNotificationsInput, UserUncheckedCreateWithoutAdminNotificationsInput>
    connectOrCreate?: UserCreateOrConnectWithoutAdminNotificationsInput
    connect?: UserWhereUniqueInput
  }

  export type EnumAdminNotificationToneFieldUpdateOperationsInput = {
    set?: $Enums.AdminNotificationTone
  }

  export type EnumAdminNotificationCategoryFieldUpdateOperationsInput = {
    set?: $Enums.AdminNotificationCategory
  }

  export type UserUpdateOneWithoutAdminNotificationsNestedInput = {
    create?: XOR<UserCreateWithoutAdminNotificationsInput, UserUncheckedCreateWithoutAdminNotificationsInput>
    connectOrCreate?: UserCreateOrConnectWithoutAdminNotificationsInput
    upsert?: UserUpsertWithoutAdminNotificationsInput
    disconnect?: UserWhereInput | boolean
    delete?: UserWhereInput | boolean
    connect?: UserWhereUniqueInput
    update?: XOR<XOR<UserUpdateToOneWithWhereWithoutAdminNotificationsInput, UserUpdateWithoutAdminNotificationsInput>, UserUncheckedUpdateWithoutAdminNotificationsInput>
  }

  export type UserCreateNestedOneWithoutPointTransactionsInput = {
    create?: XOR<UserCreateWithoutPointTransactionsInput, UserUncheckedCreateWithoutPointTransactionsInput>
    connectOrCreate?: UserCreateOrConnectWithoutPointTransactionsInput
    connect?: UserWhereUniqueInput
  }

  export type UserUpdateOneRequiredWithoutPointTransactionsNestedInput = {
    create?: XOR<UserCreateWithoutPointTransactionsInput, UserUncheckedCreateWithoutPointTransactionsInput>
    connectOrCreate?: UserCreateOrConnectWithoutPointTransactionsInput
    upsert?: UserUpsertWithoutPointTransactionsInput
    connect?: UserWhereUniqueInput
    update?: XOR<XOR<UserUpdateToOneWithWhereWithoutPointTransactionsInput, UserUpdateWithoutPointTransactionsInput>, UserUncheckedUpdateWithoutPointTransactionsInput>
  }

  export type ReportCreateNestedManyWithoutSiteInput = {
    create?: XOR<ReportCreateWithoutSiteInput, ReportUncheckedCreateWithoutSiteInput> | ReportCreateWithoutSiteInput[] | ReportUncheckedCreateWithoutSiteInput[]
    connectOrCreate?: ReportCreateOrConnectWithoutSiteInput | ReportCreateOrConnectWithoutSiteInput[]
    createMany?: ReportCreateManySiteInputEnvelope
    connect?: ReportWhereUniqueInput | ReportWhereUniqueInput[]
  }

  export type CleanupEventCreateNestedManyWithoutSiteInput = {
    create?: XOR<CleanupEventCreateWithoutSiteInput, CleanupEventUncheckedCreateWithoutSiteInput> | CleanupEventCreateWithoutSiteInput[] | CleanupEventUncheckedCreateWithoutSiteInput[]
    connectOrCreate?: CleanupEventCreateOrConnectWithoutSiteInput | CleanupEventCreateOrConnectWithoutSiteInput[]
    createMany?: CleanupEventCreateManySiteInputEnvelope
    connect?: CleanupEventWhereUniqueInput | CleanupEventWhereUniqueInput[]
  }

  export type ReportUncheckedCreateNestedManyWithoutSiteInput = {
    create?: XOR<ReportCreateWithoutSiteInput, ReportUncheckedCreateWithoutSiteInput> | ReportCreateWithoutSiteInput[] | ReportUncheckedCreateWithoutSiteInput[]
    connectOrCreate?: ReportCreateOrConnectWithoutSiteInput | ReportCreateOrConnectWithoutSiteInput[]
    createMany?: ReportCreateManySiteInputEnvelope
    connect?: ReportWhereUniqueInput | ReportWhereUniqueInput[]
  }

  export type CleanupEventUncheckedCreateNestedManyWithoutSiteInput = {
    create?: XOR<CleanupEventCreateWithoutSiteInput, CleanupEventUncheckedCreateWithoutSiteInput> | CleanupEventCreateWithoutSiteInput[] | CleanupEventUncheckedCreateWithoutSiteInput[]
    connectOrCreate?: CleanupEventCreateOrConnectWithoutSiteInput | CleanupEventCreateOrConnectWithoutSiteInput[]
    createMany?: CleanupEventCreateManySiteInputEnvelope
    connect?: CleanupEventWhereUniqueInput | CleanupEventWhereUniqueInput[]
  }

  export type FloatFieldUpdateOperationsInput = {
    set?: number
    increment?: number
    decrement?: number
    multiply?: number
    divide?: number
  }

  export type EnumSiteStatusFieldUpdateOperationsInput = {
    set?: $Enums.SiteStatus
  }

  export type ReportUpdateManyWithoutSiteNestedInput = {
    create?: XOR<ReportCreateWithoutSiteInput, ReportUncheckedCreateWithoutSiteInput> | ReportCreateWithoutSiteInput[] | ReportUncheckedCreateWithoutSiteInput[]
    connectOrCreate?: ReportCreateOrConnectWithoutSiteInput | ReportCreateOrConnectWithoutSiteInput[]
    upsert?: ReportUpsertWithWhereUniqueWithoutSiteInput | ReportUpsertWithWhereUniqueWithoutSiteInput[]
    createMany?: ReportCreateManySiteInputEnvelope
    set?: ReportWhereUniqueInput | ReportWhereUniqueInput[]
    disconnect?: ReportWhereUniqueInput | ReportWhereUniqueInput[]
    delete?: ReportWhereUniqueInput | ReportWhereUniqueInput[]
    connect?: ReportWhereUniqueInput | ReportWhereUniqueInput[]
    update?: ReportUpdateWithWhereUniqueWithoutSiteInput | ReportUpdateWithWhereUniqueWithoutSiteInput[]
    updateMany?: ReportUpdateManyWithWhereWithoutSiteInput | ReportUpdateManyWithWhereWithoutSiteInput[]
    deleteMany?: ReportScalarWhereInput | ReportScalarWhereInput[]
  }

  export type CleanupEventUpdateManyWithoutSiteNestedInput = {
    create?: XOR<CleanupEventCreateWithoutSiteInput, CleanupEventUncheckedCreateWithoutSiteInput> | CleanupEventCreateWithoutSiteInput[] | CleanupEventUncheckedCreateWithoutSiteInput[]
    connectOrCreate?: CleanupEventCreateOrConnectWithoutSiteInput | CleanupEventCreateOrConnectWithoutSiteInput[]
    upsert?: CleanupEventUpsertWithWhereUniqueWithoutSiteInput | CleanupEventUpsertWithWhereUniqueWithoutSiteInput[]
    createMany?: CleanupEventCreateManySiteInputEnvelope
    set?: CleanupEventWhereUniqueInput | CleanupEventWhereUniqueInput[]
    disconnect?: CleanupEventWhereUniqueInput | CleanupEventWhereUniqueInput[]
    delete?: CleanupEventWhereUniqueInput | CleanupEventWhereUniqueInput[]
    connect?: CleanupEventWhereUniqueInput | CleanupEventWhereUniqueInput[]
    update?: CleanupEventUpdateWithWhereUniqueWithoutSiteInput | CleanupEventUpdateWithWhereUniqueWithoutSiteInput[]
    updateMany?: CleanupEventUpdateManyWithWhereWithoutSiteInput | CleanupEventUpdateManyWithWhereWithoutSiteInput[]
    deleteMany?: CleanupEventScalarWhereInput | CleanupEventScalarWhereInput[]
  }

  export type ReportUncheckedUpdateManyWithoutSiteNestedInput = {
    create?: XOR<ReportCreateWithoutSiteInput, ReportUncheckedCreateWithoutSiteInput> | ReportCreateWithoutSiteInput[] | ReportUncheckedCreateWithoutSiteInput[]
    connectOrCreate?: ReportCreateOrConnectWithoutSiteInput | ReportCreateOrConnectWithoutSiteInput[]
    upsert?: ReportUpsertWithWhereUniqueWithoutSiteInput | ReportUpsertWithWhereUniqueWithoutSiteInput[]
    createMany?: ReportCreateManySiteInputEnvelope
    set?: ReportWhereUniqueInput | ReportWhereUniqueInput[]
    disconnect?: ReportWhereUniqueInput | ReportWhereUniqueInput[]
    delete?: ReportWhereUniqueInput | ReportWhereUniqueInput[]
    connect?: ReportWhereUniqueInput | ReportWhereUniqueInput[]
    update?: ReportUpdateWithWhereUniqueWithoutSiteInput | ReportUpdateWithWhereUniqueWithoutSiteInput[]
    updateMany?: ReportUpdateManyWithWhereWithoutSiteInput | ReportUpdateManyWithWhereWithoutSiteInput[]
    deleteMany?: ReportScalarWhereInput | ReportScalarWhereInput[]
  }

  export type CleanupEventUncheckedUpdateManyWithoutSiteNestedInput = {
    create?: XOR<CleanupEventCreateWithoutSiteInput, CleanupEventUncheckedCreateWithoutSiteInput> | CleanupEventCreateWithoutSiteInput[] | CleanupEventUncheckedCreateWithoutSiteInput[]
    connectOrCreate?: CleanupEventCreateOrConnectWithoutSiteInput | CleanupEventCreateOrConnectWithoutSiteInput[]
    upsert?: CleanupEventUpsertWithWhereUniqueWithoutSiteInput | CleanupEventUpsertWithWhereUniqueWithoutSiteInput[]
    createMany?: CleanupEventCreateManySiteInputEnvelope
    set?: CleanupEventWhereUniqueInput | CleanupEventWhereUniqueInput[]
    disconnect?: CleanupEventWhereUniqueInput | CleanupEventWhereUniqueInput[]
    delete?: CleanupEventWhereUniqueInput | CleanupEventWhereUniqueInput[]
    connect?: CleanupEventWhereUniqueInput | CleanupEventWhereUniqueInput[]
    update?: CleanupEventUpdateWithWhereUniqueWithoutSiteInput | CleanupEventUpdateWithWhereUniqueWithoutSiteInput[]
    updateMany?: CleanupEventUpdateManyWithWhereWithoutSiteInput | CleanupEventUpdateManyWithWhereWithoutSiteInput[]
    deleteMany?: CleanupEventScalarWhereInput | CleanupEventScalarWhereInput[]
  }

  export type ReportCreatemediaUrlsInput = {
    set: string[]
  }

  export type SiteCreateNestedOneWithoutReportsInput = {
    create?: XOR<SiteCreateWithoutReportsInput, SiteUncheckedCreateWithoutReportsInput>
    connectOrCreate?: SiteCreateOrConnectWithoutReportsInput
    connect?: SiteWhereUniqueInput
  }

  export type UserCreateNestedOneWithoutReportsInput = {
    create?: XOR<UserCreateWithoutReportsInput, UserUncheckedCreateWithoutReportsInput>
    connectOrCreate?: UserCreateOrConnectWithoutReportsInput
    connect?: UserWhereUniqueInput
  }

  export type UserCreateNestedOneWithoutModeratedReportsInput = {
    create?: XOR<UserCreateWithoutModeratedReportsInput, UserUncheckedCreateWithoutModeratedReportsInput>
    connectOrCreate?: UserCreateOrConnectWithoutModeratedReportsInput
    connect?: UserWhereUniqueInput
  }

  export type ReportCreateNestedOneWithoutPotentialDuplicatesInput = {
    create?: XOR<ReportCreateWithoutPotentialDuplicatesInput, ReportUncheckedCreateWithoutPotentialDuplicatesInput>
    connectOrCreate?: ReportCreateOrConnectWithoutPotentialDuplicatesInput
    connect?: ReportWhereUniqueInput
  }

  export type ReportCreateNestedManyWithoutPotentialDuplicateOfInput = {
    create?: XOR<ReportCreateWithoutPotentialDuplicateOfInput, ReportUncheckedCreateWithoutPotentialDuplicateOfInput> | ReportCreateWithoutPotentialDuplicateOfInput[] | ReportUncheckedCreateWithoutPotentialDuplicateOfInput[]
    connectOrCreate?: ReportCreateOrConnectWithoutPotentialDuplicateOfInput | ReportCreateOrConnectWithoutPotentialDuplicateOfInput[]
    createMany?: ReportCreateManyPotentialDuplicateOfInputEnvelope
    connect?: ReportWhereUniqueInput | ReportWhereUniqueInput[]
  }

  export type ReportCoReporterCreateNestedManyWithoutReportInput = {
    create?: XOR<ReportCoReporterCreateWithoutReportInput, ReportCoReporterUncheckedCreateWithoutReportInput> | ReportCoReporterCreateWithoutReportInput[] | ReportCoReporterUncheckedCreateWithoutReportInput[]
    connectOrCreate?: ReportCoReporterCreateOrConnectWithoutReportInput | ReportCoReporterCreateOrConnectWithoutReportInput[]
    createMany?: ReportCoReporterCreateManyReportInputEnvelope
    connect?: ReportCoReporterWhereUniqueInput | ReportCoReporterWhereUniqueInput[]
  }

  export type ReportUncheckedCreateNestedManyWithoutPotentialDuplicateOfInput = {
    create?: XOR<ReportCreateWithoutPotentialDuplicateOfInput, ReportUncheckedCreateWithoutPotentialDuplicateOfInput> | ReportCreateWithoutPotentialDuplicateOfInput[] | ReportUncheckedCreateWithoutPotentialDuplicateOfInput[]
    connectOrCreate?: ReportCreateOrConnectWithoutPotentialDuplicateOfInput | ReportCreateOrConnectWithoutPotentialDuplicateOfInput[]
    createMany?: ReportCreateManyPotentialDuplicateOfInputEnvelope
    connect?: ReportWhereUniqueInput | ReportWhereUniqueInput[]
  }

  export type ReportCoReporterUncheckedCreateNestedManyWithoutReportInput = {
    create?: XOR<ReportCoReporterCreateWithoutReportInput, ReportCoReporterUncheckedCreateWithoutReportInput> | ReportCoReporterCreateWithoutReportInput[] | ReportCoReporterUncheckedCreateWithoutReportInput[]
    connectOrCreate?: ReportCoReporterCreateOrConnectWithoutReportInput | ReportCoReporterCreateOrConnectWithoutReportInput[]
    createMany?: ReportCoReporterCreateManyReportInputEnvelope
    connect?: ReportCoReporterWhereUniqueInput | ReportCoReporterWhereUniqueInput[]
  }

  export type ReportUpdatemediaUrlsInput = {
    set?: string[]
    push?: string | string[]
  }

  export type NullableIntFieldUpdateOperationsInput = {
    set?: number | null
    increment?: number
    decrement?: number
    multiply?: number
    divide?: number
  }

  export type EnumReportStatusFieldUpdateOperationsInput = {
    set?: $Enums.ReportStatus
  }

  export type SiteUpdateOneRequiredWithoutReportsNestedInput = {
    create?: XOR<SiteCreateWithoutReportsInput, SiteUncheckedCreateWithoutReportsInput>
    connectOrCreate?: SiteCreateOrConnectWithoutReportsInput
    upsert?: SiteUpsertWithoutReportsInput
    connect?: SiteWhereUniqueInput
    update?: XOR<XOR<SiteUpdateToOneWithWhereWithoutReportsInput, SiteUpdateWithoutReportsInput>, SiteUncheckedUpdateWithoutReportsInput>
  }

  export type UserUpdateOneWithoutReportsNestedInput = {
    create?: XOR<UserCreateWithoutReportsInput, UserUncheckedCreateWithoutReportsInput>
    connectOrCreate?: UserCreateOrConnectWithoutReportsInput
    upsert?: UserUpsertWithoutReportsInput
    disconnect?: UserWhereInput | boolean
    delete?: UserWhereInput | boolean
    connect?: UserWhereUniqueInput
    update?: XOR<XOR<UserUpdateToOneWithWhereWithoutReportsInput, UserUpdateWithoutReportsInput>, UserUncheckedUpdateWithoutReportsInput>
  }

  export type UserUpdateOneWithoutModeratedReportsNestedInput = {
    create?: XOR<UserCreateWithoutModeratedReportsInput, UserUncheckedCreateWithoutModeratedReportsInput>
    connectOrCreate?: UserCreateOrConnectWithoutModeratedReportsInput
    upsert?: UserUpsertWithoutModeratedReportsInput
    disconnect?: UserWhereInput | boolean
    delete?: UserWhereInput | boolean
    connect?: UserWhereUniqueInput
    update?: XOR<XOR<UserUpdateToOneWithWhereWithoutModeratedReportsInput, UserUpdateWithoutModeratedReportsInput>, UserUncheckedUpdateWithoutModeratedReportsInput>
  }

  export type ReportUpdateOneWithoutPotentialDuplicatesNestedInput = {
    create?: XOR<ReportCreateWithoutPotentialDuplicatesInput, ReportUncheckedCreateWithoutPotentialDuplicatesInput>
    connectOrCreate?: ReportCreateOrConnectWithoutPotentialDuplicatesInput
    upsert?: ReportUpsertWithoutPotentialDuplicatesInput
    disconnect?: ReportWhereInput | boolean
    delete?: ReportWhereInput | boolean
    connect?: ReportWhereUniqueInput
    update?: XOR<XOR<ReportUpdateToOneWithWhereWithoutPotentialDuplicatesInput, ReportUpdateWithoutPotentialDuplicatesInput>, ReportUncheckedUpdateWithoutPotentialDuplicatesInput>
  }

  export type ReportUpdateManyWithoutPotentialDuplicateOfNestedInput = {
    create?: XOR<ReportCreateWithoutPotentialDuplicateOfInput, ReportUncheckedCreateWithoutPotentialDuplicateOfInput> | ReportCreateWithoutPotentialDuplicateOfInput[] | ReportUncheckedCreateWithoutPotentialDuplicateOfInput[]
    connectOrCreate?: ReportCreateOrConnectWithoutPotentialDuplicateOfInput | ReportCreateOrConnectWithoutPotentialDuplicateOfInput[]
    upsert?: ReportUpsertWithWhereUniqueWithoutPotentialDuplicateOfInput | ReportUpsertWithWhereUniqueWithoutPotentialDuplicateOfInput[]
    createMany?: ReportCreateManyPotentialDuplicateOfInputEnvelope
    set?: ReportWhereUniqueInput | ReportWhereUniqueInput[]
    disconnect?: ReportWhereUniqueInput | ReportWhereUniqueInput[]
    delete?: ReportWhereUniqueInput | ReportWhereUniqueInput[]
    connect?: ReportWhereUniqueInput | ReportWhereUniqueInput[]
    update?: ReportUpdateWithWhereUniqueWithoutPotentialDuplicateOfInput | ReportUpdateWithWhereUniqueWithoutPotentialDuplicateOfInput[]
    updateMany?: ReportUpdateManyWithWhereWithoutPotentialDuplicateOfInput | ReportUpdateManyWithWhereWithoutPotentialDuplicateOfInput[]
    deleteMany?: ReportScalarWhereInput | ReportScalarWhereInput[]
  }

  export type ReportCoReporterUpdateManyWithoutReportNestedInput = {
    create?: XOR<ReportCoReporterCreateWithoutReportInput, ReportCoReporterUncheckedCreateWithoutReportInput> | ReportCoReporterCreateWithoutReportInput[] | ReportCoReporterUncheckedCreateWithoutReportInput[]
    connectOrCreate?: ReportCoReporterCreateOrConnectWithoutReportInput | ReportCoReporterCreateOrConnectWithoutReportInput[]
    upsert?: ReportCoReporterUpsertWithWhereUniqueWithoutReportInput | ReportCoReporterUpsertWithWhereUniqueWithoutReportInput[]
    createMany?: ReportCoReporterCreateManyReportInputEnvelope
    set?: ReportCoReporterWhereUniqueInput | ReportCoReporterWhereUniqueInput[]
    disconnect?: ReportCoReporterWhereUniqueInput | ReportCoReporterWhereUniqueInput[]
    delete?: ReportCoReporterWhereUniqueInput | ReportCoReporterWhereUniqueInput[]
    connect?: ReportCoReporterWhereUniqueInput | ReportCoReporterWhereUniqueInput[]
    update?: ReportCoReporterUpdateWithWhereUniqueWithoutReportInput | ReportCoReporterUpdateWithWhereUniqueWithoutReportInput[]
    updateMany?: ReportCoReporterUpdateManyWithWhereWithoutReportInput | ReportCoReporterUpdateManyWithWhereWithoutReportInput[]
    deleteMany?: ReportCoReporterScalarWhereInput | ReportCoReporterScalarWhereInput[]
  }

  export type ReportUncheckedUpdateManyWithoutPotentialDuplicateOfNestedInput = {
    create?: XOR<ReportCreateWithoutPotentialDuplicateOfInput, ReportUncheckedCreateWithoutPotentialDuplicateOfInput> | ReportCreateWithoutPotentialDuplicateOfInput[] | ReportUncheckedCreateWithoutPotentialDuplicateOfInput[]
    connectOrCreate?: ReportCreateOrConnectWithoutPotentialDuplicateOfInput | ReportCreateOrConnectWithoutPotentialDuplicateOfInput[]
    upsert?: ReportUpsertWithWhereUniqueWithoutPotentialDuplicateOfInput | ReportUpsertWithWhereUniqueWithoutPotentialDuplicateOfInput[]
    createMany?: ReportCreateManyPotentialDuplicateOfInputEnvelope
    set?: ReportWhereUniqueInput | ReportWhereUniqueInput[]
    disconnect?: ReportWhereUniqueInput | ReportWhereUniqueInput[]
    delete?: ReportWhereUniqueInput | ReportWhereUniqueInput[]
    connect?: ReportWhereUniqueInput | ReportWhereUniqueInput[]
    update?: ReportUpdateWithWhereUniqueWithoutPotentialDuplicateOfInput | ReportUpdateWithWhereUniqueWithoutPotentialDuplicateOfInput[]
    updateMany?: ReportUpdateManyWithWhereWithoutPotentialDuplicateOfInput | ReportUpdateManyWithWhereWithoutPotentialDuplicateOfInput[]
    deleteMany?: ReportScalarWhereInput | ReportScalarWhereInput[]
  }

  export type ReportCoReporterUncheckedUpdateManyWithoutReportNestedInput = {
    create?: XOR<ReportCoReporterCreateWithoutReportInput, ReportCoReporterUncheckedCreateWithoutReportInput> | ReportCoReporterCreateWithoutReportInput[] | ReportCoReporterUncheckedCreateWithoutReportInput[]
    connectOrCreate?: ReportCoReporterCreateOrConnectWithoutReportInput | ReportCoReporterCreateOrConnectWithoutReportInput[]
    upsert?: ReportCoReporterUpsertWithWhereUniqueWithoutReportInput | ReportCoReporterUpsertWithWhereUniqueWithoutReportInput[]
    createMany?: ReportCoReporterCreateManyReportInputEnvelope
    set?: ReportCoReporterWhereUniqueInput | ReportCoReporterWhereUniqueInput[]
    disconnect?: ReportCoReporterWhereUniqueInput | ReportCoReporterWhereUniqueInput[]
    delete?: ReportCoReporterWhereUniqueInput | ReportCoReporterWhereUniqueInput[]
    connect?: ReportCoReporterWhereUniqueInput | ReportCoReporterWhereUniqueInput[]
    update?: ReportCoReporterUpdateWithWhereUniqueWithoutReportInput | ReportCoReporterUpdateWithWhereUniqueWithoutReportInput[]
    updateMany?: ReportCoReporterUpdateManyWithWhereWithoutReportInput | ReportCoReporterUpdateManyWithWhereWithoutReportInput[]
    deleteMany?: ReportCoReporterScalarWhereInput | ReportCoReporterScalarWhereInput[]
  }

  export type ReportCreateNestedOneWithoutCoReportersInput = {
    create?: XOR<ReportCreateWithoutCoReportersInput, ReportUncheckedCreateWithoutCoReportersInput>
    connectOrCreate?: ReportCreateOrConnectWithoutCoReportersInput
    connect?: ReportWhereUniqueInput
  }

  export type UserCreateNestedOneWithoutCoReportedReportsInput = {
    create?: XOR<UserCreateWithoutCoReportedReportsInput, UserUncheckedCreateWithoutCoReportedReportsInput>
    connectOrCreate?: UserCreateOrConnectWithoutCoReportedReportsInput
    connect?: UserWhereUniqueInput
  }

  export type ReportUpdateOneRequiredWithoutCoReportersNestedInput = {
    create?: XOR<ReportCreateWithoutCoReportersInput, ReportUncheckedCreateWithoutCoReportersInput>
    connectOrCreate?: ReportCreateOrConnectWithoutCoReportersInput
    upsert?: ReportUpsertWithoutCoReportersInput
    connect?: ReportWhereUniqueInput
    update?: XOR<XOR<ReportUpdateToOneWithWhereWithoutCoReportersInput, ReportUpdateWithoutCoReportersInput>, ReportUncheckedUpdateWithoutCoReportersInput>
  }

  export type UserUpdateOneRequiredWithoutCoReportedReportsNestedInput = {
    create?: XOR<UserCreateWithoutCoReportedReportsInput, UserUncheckedCreateWithoutCoReportedReportsInput>
    connectOrCreate?: UserCreateOrConnectWithoutCoReportedReportsInput
    upsert?: UserUpsertWithoutCoReportedReportsInput
    connect?: UserWhereUniqueInput
    update?: XOR<XOR<UserUpdateToOneWithWhereWithoutCoReportedReportsInput, UserUpdateWithoutCoReportedReportsInput>, UserUncheckedUpdateWithoutCoReportedReportsInput>
  }

  export type SiteCreateNestedOneWithoutEventsInput = {
    create?: XOR<SiteCreateWithoutEventsInput, SiteUncheckedCreateWithoutEventsInput>
    connectOrCreate?: SiteCreateOrConnectWithoutEventsInput
    connect?: SiteWhereUniqueInput
  }

  export type SiteUpdateOneRequiredWithoutEventsNestedInput = {
    create?: XOR<SiteCreateWithoutEventsInput, SiteUncheckedCreateWithoutEventsInput>
    connectOrCreate?: SiteCreateOrConnectWithoutEventsInput
    upsert?: SiteUpsertWithoutEventsInput
    connect?: SiteWhereUniqueInput
    update?: XOR<XOR<SiteUpdateToOneWithWhereWithoutEventsInput, SiteUpdateWithoutEventsInput>, SiteUncheckedUpdateWithoutEventsInput>
  }

  export type NestedStringFilter<$PrismaModel = never> = {
    equals?: string | StringFieldRefInput<$PrismaModel>
    in?: string[] | ListStringFieldRefInput<$PrismaModel>
    notIn?: string[] | ListStringFieldRefInput<$PrismaModel>
    lt?: string | StringFieldRefInput<$PrismaModel>
    lte?: string | StringFieldRefInput<$PrismaModel>
    gt?: string | StringFieldRefInput<$PrismaModel>
    gte?: string | StringFieldRefInput<$PrismaModel>
    contains?: string | StringFieldRefInput<$PrismaModel>
    startsWith?: string | StringFieldRefInput<$PrismaModel>
    endsWith?: string | StringFieldRefInput<$PrismaModel>
    not?: NestedStringFilter<$PrismaModel> | string
  }

  export type NestedDateTimeFilter<$PrismaModel = never> = {
    equals?: Date | string | DateTimeFieldRefInput<$PrismaModel>
    in?: Date[] | string[] | ListDateTimeFieldRefInput<$PrismaModel>
    notIn?: Date[] | string[] | ListDateTimeFieldRefInput<$PrismaModel>
    lt?: Date | string | DateTimeFieldRefInput<$PrismaModel>
    lte?: Date | string | DateTimeFieldRefInput<$PrismaModel>
    gt?: Date | string | DateTimeFieldRefInput<$PrismaModel>
    gte?: Date | string | DateTimeFieldRefInput<$PrismaModel>
    not?: NestedDateTimeFilter<$PrismaModel> | Date | string
  }

  export type NestedEnumRoleFilter<$PrismaModel = never> = {
    equals?: $Enums.Role | EnumRoleFieldRefInput<$PrismaModel>
    in?: $Enums.Role[] | ListEnumRoleFieldRefInput<$PrismaModel>
    notIn?: $Enums.Role[] | ListEnumRoleFieldRefInput<$PrismaModel>
    not?: NestedEnumRoleFilter<$PrismaModel> | $Enums.Role
  }

  export type NestedEnumUserStatusFilter<$PrismaModel = never> = {
    equals?: $Enums.UserStatus | EnumUserStatusFieldRefInput<$PrismaModel>
    in?: $Enums.UserStatus[] | ListEnumUserStatusFieldRefInput<$PrismaModel>
    notIn?: $Enums.UserStatus[] | ListEnumUserStatusFieldRefInput<$PrismaModel>
    not?: NestedEnumUserStatusFilter<$PrismaModel> | $Enums.UserStatus
  }

  export type NestedBoolFilter<$PrismaModel = never> = {
    equals?: boolean | BooleanFieldRefInput<$PrismaModel>
    not?: NestedBoolFilter<$PrismaModel> | boolean
  }

  export type NestedIntFilter<$PrismaModel = never> = {
    equals?: number | IntFieldRefInput<$PrismaModel>
    in?: number[] | ListIntFieldRefInput<$PrismaModel>
    notIn?: number[] | ListIntFieldRefInput<$PrismaModel>
    lt?: number | IntFieldRefInput<$PrismaModel>
    lte?: number | IntFieldRefInput<$PrismaModel>
    gt?: number | IntFieldRefInput<$PrismaModel>
    gte?: number | IntFieldRefInput<$PrismaModel>
    not?: NestedIntFilter<$PrismaModel> | number
  }

  export type NestedDateTimeNullableFilter<$PrismaModel = never> = {
    equals?: Date | string | DateTimeFieldRefInput<$PrismaModel> | null
    in?: Date[] | string[] | ListDateTimeFieldRefInput<$PrismaModel> | null
    notIn?: Date[] | string[] | ListDateTimeFieldRefInput<$PrismaModel> | null
    lt?: Date | string | DateTimeFieldRefInput<$PrismaModel>
    lte?: Date | string | DateTimeFieldRefInput<$PrismaModel>
    gt?: Date | string | DateTimeFieldRefInput<$PrismaModel>
    gte?: Date | string | DateTimeFieldRefInput<$PrismaModel>
    not?: NestedDateTimeNullableFilter<$PrismaModel> | Date | string | null
  }

  export type NestedStringWithAggregatesFilter<$PrismaModel = never> = {
    equals?: string | StringFieldRefInput<$PrismaModel>
    in?: string[] | ListStringFieldRefInput<$PrismaModel>
    notIn?: string[] | ListStringFieldRefInput<$PrismaModel>
    lt?: string | StringFieldRefInput<$PrismaModel>
    lte?: string | StringFieldRefInput<$PrismaModel>
    gt?: string | StringFieldRefInput<$PrismaModel>
    gte?: string | StringFieldRefInput<$PrismaModel>
    contains?: string | StringFieldRefInput<$PrismaModel>
    startsWith?: string | StringFieldRefInput<$PrismaModel>
    endsWith?: string | StringFieldRefInput<$PrismaModel>
    not?: NestedStringWithAggregatesFilter<$PrismaModel> | string
    _count?: NestedIntFilter<$PrismaModel>
    _min?: NestedStringFilter<$PrismaModel>
    _max?: NestedStringFilter<$PrismaModel>
  }

  export type NestedDateTimeWithAggregatesFilter<$PrismaModel = never> = {
    equals?: Date | string | DateTimeFieldRefInput<$PrismaModel>
    in?: Date[] | string[] | ListDateTimeFieldRefInput<$PrismaModel>
    notIn?: Date[] | string[] | ListDateTimeFieldRefInput<$PrismaModel>
    lt?: Date | string | DateTimeFieldRefInput<$PrismaModel>
    lte?: Date | string | DateTimeFieldRefInput<$PrismaModel>
    gt?: Date | string | DateTimeFieldRefInput<$PrismaModel>
    gte?: Date | string | DateTimeFieldRefInput<$PrismaModel>
    not?: NestedDateTimeWithAggregatesFilter<$PrismaModel> | Date | string
    _count?: NestedIntFilter<$PrismaModel>
    _min?: NestedDateTimeFilter<$PrismaModel>
    _max?: NestedDateTimeFilter<$PrismaModel>
  }

  export type NestedEnumRoleWithAggregatesFilter<$PrismaModel = never> = {
    equals?: $Enums.Role | EnumRoleFieldRefInput<$PrismaModel>
    in?: $Enums.Role[] | ListEnumRoleFieldRefInput<$PrismaModel>
    notIn?: $Enums.Role[] | ListEnumRoleFieldRefInput<$PrismaModel>
    not?: NestedEnumRoleWithAggregatesFilter<$PrismaModel> | $Enums.Role
    _count?: NestedIntFilter<$PrismaModel>
    _min?: NestedEnumRoleFilter<$PrismaModel>
    _max?: NestedEnumRoleFilter<$PrismaModel>
  }

  export type NestedEnumUserStatusWithAggregatesFilter<$PrismaModel = never> = {
    equals?: $Enums.UserStatus | EnumUserStatusFieldRefInput<$PrismaModel>
    in?: $Enums.UserStatus[] | ListEnumUserStatusFieldRefInput<$PrismaModel>
    notIn?: $Enums.UserStatus[] | ListEnumUserStatusFieldRefInput<$PrismaModel>
    not?: NestedEnumUserStatusWithAggregatesFilter<$PrismaModel> | $Enums.UserStatus
    _count?: NestedIntFilter<$PrismaModel>
    _min?: NestedEnumUserStatusFilter<$PrismaModel>
    _max?: NestedEnumUserStatusFilter<$PrismaModel>
  }

  export type NestedBoolWithAggregatesFilter<$PrismaModel = never> = {
    equals?: boolean | BooleanFieldRefInput<$PrismaModel>
    not?: NestedBoolWithAggregatesFilter<$PrismaModel> | boolean
    _count?: NestedIntFilter<$PrismaModel>
    _min?: NestedBoolFilter<$PrismaModel>
    _max?: NestedBoolFilter<$PrismaModel>
  }

  export type NestedIntWithAggregatesFilter<$PrismaModel = never> = {
    equals?: number | IntFieldRefInput<$PrismaModel>
    in?: number[] | ListIntFieldRefInput<$PrismaModel>
    notIn?: number[] | ListIntFieldRefInput<$PrismaModel>
    lt?: number | IntFieldRefInput<$PrismaModel>
    lte?: number | IntFieldRefInput<$PrismaModel>
    gt?: number | IntFieldRefInput<$PrismaModel>
    gte?: number | IntFieldRefInput<$PrismaModel>
    not?: NestedIntWithAggregatesFilter<$PrismaModel> | number
    _count?: NestedIntFilter<$PrismaModel>
    _avg?: NestedFloatFilter<$PrismaModel>
    _sum?: NestedIntFilter<$PrismaModel>
    _min?: NestedIntFilter<$PrismaModel>
    _max?: NestedIntFilter<$PrismaModel>
  }

  export type NestedFloatFilter<$PrismaModel = never> = {
    equals?: number | FloatFieldRefInput<$PrismaModel>
    in?: number[] | ListFloatFieldRefInput<$PrismaModel>
    notIn?: number[] | ListFloatFieldRefInput<$PrismaModel>
    lt?: number | FloatFieldRefInput<$PrismaModel>
    lte?: number | FloatFieldRefInput<$PrismaModel>
    gt?: number | FloatFieldRefInput<$PrismaModel>
    gte?: number | FloatFieldRefInput<$PrismaModel>
    not?: NestedFloatFilter<$PrismaModel> | number
  }

  export type NestedDateTimeNullableWithAggregatesFilter<$PrismaModel = never> = {
    equals?: Date | string | DateTimeFieldRefInput<$PrismaModel> | null
    in?: Date[] | string[] | ListDateTimeFieldRefInput<$PrismaModel> | null
    notIn?: Date[] | string[] | ListDateTimeFieldRefInput<$PrismaModel> | null
    lt?: Date | string | DateTimeFieldRefInput<$PrismaModel>
    lte?: Date | string | DateTimeFieldRefInput<$PrismaModel>
    gt?: Date | string | DateTimeFieldRefInput<$PrismaModel>
    gte?: Date | string | DateTimeFieldRefInput<$PrismaModel>
    not?: NestedDateTimeNullableWithAggregatesFilter<$PrismaModel> | Date | string | null
    _count?: NestedIntNullableFilter<$PrismaModel>
    _min?: NestedDateTimeNullableFilter<$PrismaModel>
    _max?: NestedDateTimeNullableFilter<$PrismaModel>
  }

  export type NestedIntNullableFilter<$PrismaModel = never> = {
    equals?: number | IntFieldRefInput<$PrismaModel> | null
    in?: number[] | ListIntFieldRefInput<$PrismaModel> | null
    notIn?: number[] | ListIntFieldRefInput<$PrismaModel> | null
    lt?: number | IntFieldRefInput<$PrismaModel>
    lte?: number | IntFieldRefInput<$PrismaModel>
    gt?: number | IntFieldRefInput<$PrismaModel>
    gte?: number | IntFieldRefInput<$PrismaModel>
    not?: NestedIntNullableFilter<$PrismaModel> | number | null
  }

  export type NestedStringNullableFilter<$PrismaModel = never> = {
    equals?: string | StringFieldRefInput<$PrismaModel> | null
    in?: string[] | ListStringFieldRefInput<$PrismaModel> | null
    notIn?: string[] | ListStringFieldRefInput<$PrismaModel> | null
    lt?: string | StringFieldRefInput<$PrismaModel>
    lte?: string | StringFieldRefInput<$PrismaModel>
    gt?: string | StringFieldRefInput<$PrismaModel>
    gte?: string | StringFieldRefInput<$PrismaModel>
    contains?: string | StringFieldRefInput<$PrismaModel>
    startsWith?: string | StringFieldRefInput<$PrismaModel>
    endsWith?: string | StringFieldRefInput<$PrismaModel>
    not?: NestedStringNullableFilter<$PrismaModel> | string | null
  }

  export type NestedStringNullableWithAggregatesFilter<$PrismaModel = never> = {
    equals?: string | StringFieldRefInput<$PrismaModel> | null
    in?: string[] | ListStringFieldRefInput<$PrismaModel> | null
    notIn?: string[] | ListStringFieldRefInput<$PrismaModel> | null
    lt?: string | StringFieldRefInput<$PrismaModel>
    lte?: string | StringFieldRefInput<$PrismaModel>
    gt?: string | StringFieldRefInput<$PrismaModel>
    gte?: string | StringFieldRefInput<$PrismaModel>
    contains?: string | StringFieldRefInput<$PrismaModel>
    startsWith?: string | StringFieldRefInput<$PrismaModel>
    endsWith?: string | StringFieldRefInput<$PrismaModel>
    not?: NestedStringNullableWithAggregatesFilter<$PrismaModel> | string | null
    _count?: NestedIntNullableFilter<$PrismaModel>
    _min?: NestedStringNullableFilter<$PrismaModel>
    _max?: NestedStringNullableFilter<$PrismaModel>
  }

  export type NestedEnumAdminNotificationToneFilter<$PrismaModel = never> = {
    equals?: $Enums.AdminNotificationTone | EnumAdminNotificationToneFieldRefInput<$PrismaModel>
    in?: $Enums.AdminNotificationTone[] | ListEnumAdminNotificationToneFieldRefInput<$PrismaModel>
    notIn?: $Enums.AdminNotificationTone[] | ListEnumAdminNotificationToneFieldRefInput<$PrismaModel>
    not?: NestedEnumAdminNotificationToneFilter<$PrismaModel> | $Enums.AdminNotificationTone
  }

  export type NestedEnumAdminNotificationCategoryFilter<$PrismaModel = never> = {
    equals?: $Enums.AdminNotificationCategory | EnumAdminNotificationCategoryFieldRefInput<$PrismaModel>
    in?: $Enums.AdminNotificationCategory[] | ListEnumAdminNotificationCategoryFieldRefInput<$PrismaModel>
    notIn?: $Enums.AdminNotificationCategory[] | ListEnumAdminNotificationCategoryFieldRefInput<$PrismaModel>
    not?: NestedEnumAdminNotificationCategoryFilter<$PrismaModel> | $Enums.AdminNotificationCategory
  }

  export type NestedEnumAdminNotificationToneWithAggregatesFilter<$PrismaModel = never> = {
    equals?: $Enums.AdminNotificationTone | EnumAdminNotificationToneFieldRefInput<$PrismaModel>
    in?: $Enums.AdminNotificationTone[] | ListEnumAdminNotificationToneFieldRefInput<$PrismaModel>
    notIn?: $Enums.AdminNotificationTone[] | ListEnumAdminNotificationToneFieldRefInput<$PrismaModel>
    not?: NestedEnumAdminNotificationToneWithAggregatesFilter<$PrismaModel> | $Enums.AdminNotificationTone
    _count?: NestedIntFilter<$PrismaModel>
    _min?: NestedEnumAdminNotificationToneFilter<$PrismaModel>
    _max?: NestedEnumAdminNotificationToneFilter<$PrismaModel>
  }

  export type NestedEnumAdminNotificationCategoryWithAggregatesFilter<$PrismaModel = never> = {
    equals?: $Enums.AdminNotificationCategory | EnumAdminNotificationCategoryFieldRefInput<$PrismaModel>
    in?: $Enums.AdminNotificationCategory[] | ListEnumAdminNotificationCategoryFieldRefInput<$PrismaModel>
    notIn?: $Enums.AdminNotificationCategory[] | ListEnumAdminNotificationCategoryFieldRefInput<$PrismaModel>
    not?: NestedEnumAdminNotificationCategoryWithAggregatesFilter<$PrismaModel> | $Enums.AdminNotificationCategory
    _count?: NestedIntFilter<$PrismaModel>
    _min?: NestedEnumAdminNotificationCategoryFilter<$PrismaModel>
    _max?: NestedEnumAdminNotificationCategoryFilter<$PrismaModel>
  }
  export type NestedJsonNullableFilter<$PrismaModel = never> =
    | PatchUndefined<
        Either<Required<NestedJsonNullableFilterBase<$PrismaModel>>, Exclude<keyof Required<NestedJsonNullableFilterBase<$PrismaModel>>, 'path'>>,
        Required<NestedJsonNullableFilterBase<$PrismaModel>>
      >
    | OptionalFlat<Omit<Required<NestedJsonNullableFilterBase<$PrismaModel>>, 'path'>>

  export type NestedJsonNullableFilterBase<$PrismaModel = never> = {
    equals?: InputJsonValue | JsonFieldRefInput<$PrismaModel> | JsonNullValueFilter
    path?: string[]
    mode?: QueryMode | EnumQueryModeFieldRefInput<$PrismaModel>
    string_contains?: string | StringFieldRefInput<$PrismaModel>
    string_starts_with?: string | StringFieldRefInput<$PrismaModel>
    string_ends_with?: string | StringFieldRefInput<$PrismaModel>
    array_starts_with?: InputJsonValue | JsonFieldRefInput<$PrismaModel> | null
    array_ends_with?: InputJsonValue | JsonFieldRefInput<$PrismaModel> | null
    array_contains?: InputJsonValue | JsonFieldRefInput<$PrismaModel> | null
    lt?: InputJsonValue | JsonFieldRefInput<$PrismaModel>
    lte?: InputJsonValue | JsonFieldRefInput<$PrismaModel>
    gt?: InputJsonValue | JsonFieldRefInput<$PrismaModel>
    gte?: InputJsonValue | JsonFieldRefInput<$PrismaModel>
    not?: InputJsonValue | JsonFieldRefInput<$PrismaModel> | JsonNullValueFilter
  }

  export type NestedEnumSiteStatusFilter<$PrismaModel = never> = {
    equals?: $Enums.SiteStatus | EnumSiteStatusFieldRefInput<$PrismaModel>
    in?: $Enums.SiteStatus[] | ListEnumSiteStatusFieldRefInput<$PrismaModel>
    notIn?: $Enums.SiteStatus[] | ListEnumSiteStatusFieldRefInput<$PrismaModel>
    not?: NestedEnumSiteStatusFilter<$PrismaModel> | $Enums.SiteStatus
  }

  export type NestedFloatWithAggregatesFilter<$PrismaModel = never> = {
    equals?: number | FloatFieldRefInput<$PrismaModel>
    in?: number[] | ListFloatFieldRefInput<$PrismaModel>
    notIn?: number[] | ListFloatFieldRefInput<$PrismaModel>
    lt?: number | FloatFieldRefInput<$PrismaModel>
    lte?: number | FloatFieldRefInput<$PrismaModel>
    gt?: number | FloatFieldRefInput<$PrismaModel>
    gte?: number | FloatFieldRefInput<$PrismaModel>
    not?: NestedFloatWithAggregatesFilter<$PrismaModel> | number
    _count?: NestedIntFilter<$PrismaModel>
    _avg?: NestedFloatFilter<$PrismaModel>
    _sum?: NestedFloatFilter<$PrismaModel>
    _min?: NestedFloatFilter<$PrismaModel>
    _max?: NestedFloatFilter<$PrismaModel>
  }

  export type NestedEnumSiteStatusWithAggregatesFilter<$PrismaModel = never> = {
    equals?: $Enums.SiteStatus | EnumSiteStatusFieldRefInput<$PrismaModel>
    in?: $Enums.SiteStatus[] | ListEnumSiteStatusFieldRefInput<$PrismaModel>
    notIn?: $Enums.SiteStatus[] | ListEnumSiteStatusFieldRefInput<$PrismaModel>
    not?: NestedEnumSiteStatusWithAggregatesFilter<$PrismaModel> | $Enums.SiteStatus
    _count?: NestedIntFilter<$PrismaModel>
    _min?: NestedEnumSiteStatusFilter<$PrismaModel>
    _max?: NestedEnumSiteStatusFilter<$PrismaModel>
  }

  export type NestedEnumReportStatusFilter<$PrismaModel = never> = {
    equals?: $Enums.ReportStatus | EnumReportStatusFieldRefInput<$PrismaModel>
    in?: $Enums.ReportStatus[] | ListEnumReportStatusFieldRefInput<$PrismaModel>
    notIn?: $Enums.ReportStatus[] | ListEnumReportStatusFieldRefInput<$PrismaModel>
    not?: NestedEnumReportStatusFilter<$PrismaModel> | $Enums.ReportStatus
  }

  export type NestedIntNullableWithAggregatesFilter<$PrismaModel = never> = {
    equals?: number | IntFieldRefInput<$PrismaModel> | null
    in?: number[] | ListIntFieldRefInput<$PrismaModel> | null
    notIn?: number[] | ListIntFieldRefInput<$PrismaModel> | null
    lt?: number | IntFieldRefInput<$PrismaModel>
    lte?: number | IntFieldRefInput<$PrismaModel>
    gt?: number | IntFieldRefInput<$PrismaModel>
    gte?: number | IntFieldRefInput<$PrismaModel>
    not?: NestedIntNullableWithAggregatesFilter<$PrismaModel> | number | null
    _count?: NestedIntNullableFilter<$PrismaModel>
    _avg?: NestedFloatNullableFilter<$PrismaModel>
    _sum?: NestedIntNullableFilter<$PrismaModel>
    _min?: NestedIntNullableFilter<$PrismaModel>
    _max?: NestedIntNullableFilter<$PrismaModel>
  }

  export type NestedFloatNullableFilter<$PrismaModel = never> = {
    equals?: number | FloatFieldRefInput<$PrismaModel> | null
    in?: number[] | ListFloatFieldRefInput<$PrismaModel> | null
    notIn?: number[] | ListFloatFieldRefInput<$PrismaModel> | null
    lt?: number | FloatFieldRefInput<$PrismaModel>
    lte?: number | FloatFieldRefInput<$PrismaModel>
    gt?: number | FloatFieldRefInput<$PrismaModel>
    gte?: number | FloatFieldRefInput<$PrismaModel>
    not?: NestedFloatNullableFilter<$PrismaModel> | number | null
  }

  export type NestedEnumReportStatusWithAggregatesFilter<$PrismaModel = never> = {
    equals?: $Enums.ReportStatus | EnumReportStatusFieldRefInput<$PrismaModel>
    in?: $Enums.ReportStatus[] | ListEnumReportStatusFieldRefInput<$PrismaModel>
    notIn?: $Enums.ReportStatus[] | ListEnumReportStatusFieldRefInput<$PrismaModel>
    not?: NestedEnumReportStatusWithAggregatesFilter<$PrismaModel> | $Enums.ReportStatus
    _count?: NestedIntFilter<$PrismaModel>
    _min?: NestedEnumReportStatusFilter<$PrismaModel>
    _max?: NestedEnumReportStatusFilter<$PrismaModel>
  }

  export type ReportCreateWithoutReporterInput = {
    id?: string
    createdAt?: Date | string
    reportNumber?: string | null
    description?: string | null
    mediaUrls?: ReportCreatemediaUrlsInput | string[]
    category?: string | null
    severity?: number | null
    status?: $Enums.ReportStatus
    moderatedAt?: Date | string | null
    moderationReason?: string | null
    site: SiteCreateNestedOneWithoutReportsInput
    moderatedBy?: UserCreateNestedOneWithoutModeratedReportsInput
    potentialDuplicateOf?: ReportCreateNestedOneWithoutPotentialDuplicatesInput
    potentialDuplicates?: ReportCreateNestedManyWithoutPotentialDuplicateOfInput
    coReporters?: ReportCoReporterCreateNestedManyWithoutReportInput
  }

  export type ReportUncheckedCreateWithoutReporterInput = {
    id?: string
    createdAt?: Date | string
    reportNumber?: string | null
    siteId: string
    description?: string | null
    mediaUrls?: ReportCreatemediaUrlsInput | string[]
    category?: string | null
    severity?: number | null
    status?: $Enums.ReportStatus
    moderatedAt?: Date | string | null
    moderationReason?: string | null
    moderatedById?: string | null
    potentialDuplicateOfId?: string | null
    potentialDuplicates?: ReportUncheckedCreateNestedManyWithoutPotentialDuplicateOfInput
    coReporters?: ReportCoReporterUncheckedCreateNestedManyWithoutReportInput
  }

  export type ReportCreateOrConnectWithoutReporterInput = {
    where: ReportWhereUniqueInput
    create: XOR<ReportCreateWithoutReporterInput, ReportUncheckedCreateWithoutReporterInput>
  }

  export type ReportCreateManyReporterInputEnvelope = {
    data: ReportCreateManyReporterInput | ReportCreateManyReporterInput[]
    skipDuplicates?: boolean
  }

  export type ReportCreateWithoutModeratedByInput = {
    id?: string
    createdAt?: Date | string
    reportNumber?: string | null
    description?: string | null
    mediaUrls?: ReportCreatemediaUrlsInput | string[]
    category?: string | null
    severity?: number | null
    status?: $Enums.ReportStatus
    moderatedAt?: Date | string | null
    moderationReason?: string | null
    site: SiteCreateNestedOneWithoutReportsInput
    reporter?: UserCreateNestedOneWithoutReportsInput
    potentialDuplicateOf?: ReportCreateNestedOneWithoutPotentialDuplicatesInput
    potentialDuplicates?: ReportCreateNestedManyWithoutPotentialDuplicateOfInput
    coReporters?: ReportCoReporterCreateNestedManyWithoutReportInput
  }

  export type ReportUncheckedCreateWithoutModeratedByInput = {
    id?: string
    createdAt?: Date | string
    reportNumber?: string | null
    siteId: string
    reporterId?: string | null
    description?: string | null
    mediaUrls?: ReportCreatemediaUrlsInput | string[]
    category?: string | null
    severity?: number | null
    status?: $Enums.ReportStatus
    moderatedAt?: Date | string | null
    moderationReason?: string | null
    potentialDuplicateOfId?: string | null
    potentialDuplicates?: ReportUncheckedCreateNestedManyWithoutPotentialDuplicateOfInput
    coReporters?: ReportCoReporterUncheckedCreateNestedManyWithoutReportInput
  }

  export type ReportCreateOrConnectWithoutModeratedByInput = {
    where: ReportWhereUniqueInput
    create: XOR<ReportCreateWithoutModeratedByInput, ReportUncheckedCreateWithoutModeratedByInput>
  }

  export type ReportCreateManyModeratedByInputEnvelope = {
    data: ReportCreateManyModeratedByInput | ReportCreateManyModeratedByInput[]
    skipDuplicates?: boolean
  }

  export type AdminNotificationCreateWithoutUserInput = {
    id?: string
    createdAt?: Date | string
    updatedAt?: Date | string
    title: string
    message: string
    timeLabel: string
    tone: $Enums.AdminNotificationTone
    category: $Enums.AdminNotificationCategory
    isUnread?: boolean
    href?: string | null
  }

  export type AdminNotificationUncheckedCreateWithoutUserInput = {
    id?: string
    createdAt?: Date | string
    updatedAt?: Date | string
    title: string
    message: string
    timeLabel: string
    tone: $Enums.AdminNotificationTone
    category: $Enums.AdminNotificationCategory
    isUnread?: boolean
    href?: string | null
  }

  export type AdminNotificationCreateOrConnectWithoutUserInput = {
    where: AdminNotificationWhereUniqueInput
    create: XOR<AdminNotificationCreateWithoutUserInput, AdminNotificationUncheckedCreateWithoutUserInput>
  }

  export type AdminNotificationCreateManyUserInputEnvelope = {
    data: AdminNotificationCreateManyUserInput | AdminNotificationCreateManyUserInput[]
    skipDuplicates?: boolean
  }

  export type PointTransactionCreateWithoutUserInput = {
    id?: string
    createdAt?: Date | string
    delta: number
    balanceAfter: number
    reasonCode: string
    referenceType?: string | null
    referenceId?: string | null
    metadata?: NullableJsonNullValueInput | InputJsonValue
  }

  export type PointTransactionUncheckedCreateWithoutUserInput = {
    id?: string
    createdAt?: Date | string
    delta: number
    balanceAfter: number
    reasonCode: string
    referenceType?: string | null
    referenceId?: string | null
    metadata?: NullableJsonNullValueInput | InputJsonValue
  }

  export type PointTransactionCreateOrConnectWithoutUserInput = {
    where: PointTransactionWhereUniqueInput
    create: XOR<PointTransactionCreateWithoutUserInput, PointTransactionUncheckedCreateWithoutUserInput>
  }

  export type PointTransactionCreateManyUserInputEnvelope = {
    data: PointTransactionCreateManyUserInput | PointTransactionCreateManyUserInput[]
    skipDuplicates?: boolean
  }

  export type ReportCoReporterCreateWithoutUserInput = {
    id?: string
    createdAt?: Date | string
    report: ReportCreateNestedOneWithoutCoReportersInput
  }

  export type ReportCoReporterUncheckedCreateWithoutUserInput = {
    id?: string
    createdAt?: Date | string
    reportId: string
  }

  export type ReportCoReporterCreateOrConnectWithoutUserInput = {
    where: ReportCoReporterWhereUniqueInput
    create: XOR<ReportCoReporterCreateWithoutUserInput, ReportCoReporterUncheckedCreateWithoutUserInput>
  }

  export type ReportCoReporterCreateManyUserInputEnvelope = {
    data: ReportCoReporterCreateManyUserInput | ReportCoReporterCreateManyUserInput[]
    skipDuplicates?: boolean
  }

  export type UserSessionCreateWithoutUserInput = {
    id?: string
    createdAt?: Date | string
    tokenId: string
    refreshTokenHash: string
    deviceInfo?: string | null
    ipAddress?: string | null
    expiresAt: Date | string
    revokedAt?: Date | string | null
  }

  export type UserSessionUncheckedCreateWithoutUserInput = {
    id?: string
    createdAt?: Date | string
    tokenId: string
    refreshTokenHash: string
    deviceInfo?: string | null
    ipAddress?: string | null
    expiresAt: Date | string
    revokedAt?: Date | string | null
  }

  export type UserSessionCreateOrConnectWithoutUserInput = {
    where: UserSessionWhereUniqueInput
    create: XOR<UserSessionCreateWithoutUserInput, UserSessionUncheckedCreateWithoutUserInput>
  }

  export type UserSessionCreateManyUserInputEnvelope = {
    data: UserSessionCreateManyUserInput | UserSessionCreateManyUserInput[]
    skipDuplicates?: boolean
  }

  export type ReportUpsertWithWhereUniqueWithoutReporterInput = {
    where: ReportWhereUniqueInput
    update: XOR<ReportUpdateWithoutReporterInput, ReportUncheckedUpdateWithoutReporterInput>
    create: XOR<ReportCreateWithoutReporterInput, ReportUncheckedCreateWithoutReporterInput>
  }

  export type ReportUpdateWithWhereUniqueWithoutReporterInput = {
    where: ReportWhereUniqueInput
    data: XOR<ReportUpdateWithoutReporterInput, ReportUncheckedUpdateWithoutReporterInput>
  }

  export type ReportUpdateManyWithWhereWithoutReporterInput = {
    where: ReportScalarWhereInput
    data: XOR<ReportUpdateManyMutationInput, ReportUncheckedUpdateManyWithoutReporterInput>
  }

  export type ReportScalarWhereInput = {
    AND?: ReportScalarWhereInput | ReportScalarWhereInput[]
    OR?: ReportScalarWhereInput[]
    NOT?: ReportScalarWhereInput | ReportScalarWhereInput[]
    id?: StringFilter<"Report"> | string
    createdAt?: DateTimeFilter<"Report"> | Date | string
    reportNumber?: StringNullableFilter<"Report"> | string | null
    siteId?: StringFilter<"Report"> | string
    reporterId?: StringNullableFilter<"Report"> | string | null
    description?: StringNullableFilter<"Report"> | string | null
    mediaUrls?: StringNullableListFilter<"Report">
    category?: StringNullableFilter<"Report"> | string | null
    severity?: IntNullableFilter<"Report"> | number | null
    status?: EnumReportStatusFilter<"Report"> | $Enums.ReportStatus
    moderatedAt?: DateTimeNullableFilter<"Report"> | Date | string | null
    moderationReason?: StringNullableFilter<"Report"> | string | null
    moderatedById?: StringNullableFilter<"Report"> | string | null
    potentialDuplicateOfId?: StringNullableFilter<"Report"> | string | null
  }

  export type ReportUpsertWithWhereUniqueWithoutModeratedByInput = {
    where: ReportWhereUniqueInput
    update: XOR<ReportUpdateWithoutModeratedByInput, ReportUncheckedUpdateWithoutModeratedByInput>
    create: XOR<ReportCreateWithoutModeratedByInput, ReportUncheckedCreateWithoutModeratedByInput>
  }

  export type ReportUpdateWithWhereUniqueWithoutModeratedByInput = {
    where: ReportWhereUniqueInput
    data: XOR<ReportUpdateWithoutModeratedByInput, ReportUncheckedUpdateWithoutModeratedByInput>
  }

  export type ReportUpdateManyWithWhereWithoutModeratedByInput = {
    where: ReportScalarWhereInput
    data: XOR<ReportUpdateManyMutationInput, ReportUncheckedUpdateManyWithoutModeratedByInput>
  }

  export type AdminNotificationUpsertWithWhereUniqueWithoutUserInput = {
    where: AdminNotificationWhereUniqueInput
    update: XOR<AdminNotificationUpdateWithoutUserInput, AdminNotificationUncheckedUpdateWithoutUserInput>
    create: XOR<AdminNotificationCreateWithoutUserInput, AdminNotificationUncheckedCreateWithoutUserInput>
  }

  export type AdminNotificationUpdateWithWhereUniqueWithoutUserInput = {
    where: AdminNotificationWhereUniqueInput
    data: XOR<AdminNotificationUpdateWithoutUserInput, AdminNotificationUncheckedUpdateWithoutUserInput>
  }

  export type AdminNotificationUpdateManyWithWhereWithoutUserInput = {
    where: AdminNotificationScalarWhereInput
    data: XOR<AdminNotificationUpdateManyMutationInput, AdminNotificationUncheckedUpdateManyWithoutUserInput>
  }

  export type AdminNotificationScalarWhereInput = {
    AND?: AdminNotificationScalarWhereInput | AdminNotificationScalarWhereInput[]
    OR?: AdminNotificationScalarWhereInput[]
    NOT?: AdminNotificationScalarWhereInput | AdminNotificationScalarWhereInput[]
    id?: StringFilter<"AdminNotification"> | string
    createdAt?: DateTimeFilter<"AdminNotification"> | Date | string
    updatedAt?: DateTimeFilter<"AdminNotification"> | Date | string
    userId?: StringNullableFilter<"AdminNotification"> | string | null
    title?: StringFilter<"AdminNotification"> | string
    message?: StringFilter<"AdminNotification"> | string
    timeLabel?: StringFilter<"AdminNotification"> | string
    tone?: EnumAdminNotificationToneFilter<"AdminNotification"> | $Enums.AdminNotificationTone
    category?: EnumAdminNotificationCategoryFilter<"AdminNotification"> | $Enums.AdminNotificationCategory
    isUnread?: BoolFilter<"AdminNotification"> | boolean
    href?: StringNullableFilter<"AdminNotification"> | string | null
  }

  export type PointTransactionUpsertWithWhereUniqueWithoutUserInput = {
    where: PointTransactionWhereUniqueInput
    update: XOR<PointTransactionUpdateWithoutUserInput, PointTransactionUncheckedUpdateWithoutUserInput>
    create: XOR<PointTransactionCreateWithoutUserInput, PointTransactionUncheckedCreateWithoutUserInput>
  }

  export type PointTransactionUpdateWithWhereUniqueWithoutUserInput = {
    where: PointTransactionWhereUniqueInput
    data: XOR<PointTransactionUpdateWithoutUserInput, PointTransactionUncheckedUpdateWithoutUserInput>
  }

  export type PointTransactionUpdateManyWithWhereWithoutUserInput = {
    where: PointTransactionScalarWhereInput
    data: XOR<PointTransactionUpdateManyMutationInput, PointTransactionUncheckedUpdateManyWithoutUserInput>
  }

  export type PointTransactionScalarWhereInput = {
    AND?: PointTransactionScalarWhereInput | PointTransactionScalarWhereInput[]
    OR?: PointTransactionScalarWhereInput[]
    NOT?: PointTransactionScalarWhereInput | PointTransactionScalarWhereInput[]
    id?: StringFilter<"PointTransaction"> | string
    createdAt?: DateTimeFilter<"PointTransaction"> | Date | string
    userId?: StringFilter<"PointTransaction"> | string
    delta?: IntFilter<"PointTransaction"> | number
    balanceAfter?: IntFilter<"PointTransaction"> | number
    reasonCode?: StringFilter<"PointTransaction"> | string
    referenceType?: StringNullableFilter<"PointTransaction"> | string | null
    referenceId?: StringNullableFilter<"PointTransaction"> | string | null
    metadata?: JsonNullableFilter<"PointTransaction">
  }

  export type ReportCoReporterUpsertWithWhereUniqueWithoutUserInput = {
    where: ReportCoReporterWhereUniqueInput
    update: XOR<ReportCoReporterUpdateWithoutUserInput, ReportCoReporterUncheckedUpdateWithoutUserInput>
    create: XOR<ReportCoReporterCreateWithoutUserInput, ReportCoReporterUncheckedCreateWithoutUserInput>
  }

  export type ReportCoReporterUpdateWithWhereUniqueWithoutUserInput = {
    where: ReportCoReporterWhereUniqueInput
    data: XOR<ReportCoReporterUpdateWithoutUserInput, ReportCoReporterUncheckedUpdateWithoutUserInput>
  }

  export type ReportCoReporterUpdateManyWithWhereWithoutUserInput = {
    where: ReportCoReporterScalarWhereInput
    data: XOR<ReportCoReporterUpdateManyMutationInput, ReportCoReporterUncheckedUpdateManyWithoutUserInput>
  }

  export type ReportCoReporterScalarWhereInput = {
    AND?: ReportCoReporterScalarWhereInput | ReportCoReporterScalarWhereInput[]
    OR?: ReportCoReporterScalarWhereInput[]
    NOT?: ReportCoReporterScalarWhereInput | ReportCoReporterScalarWhereInput[]
    id?: StringFilter<"ReportCoReporter"> | string
    createdAt?: DateTimeFilter<"ReportCoReporter"> | Date | string
    reportId?: StringFilter<"ReportCoReporter"> | string
    userId?: StringFilter<"ReportCoReporter"> | string
  }

  export type UserSessionUpsertWithWhereUniqueWithoutUserInput = {
    where: UserSessionWhereUniqueInput
    update: XOR<UserSessionUpdateWithoutUserInput, UserSessionUncheckedUpdateWithoutUserInput>
    create: XOR<UserSessionCreateWithoutUserInput, UserSessionUncheckedCreateWithoutUserInput>
  }

  export type UserSessionUpdateWithWhereUniqueWithoutUserInput = {
    where: UserSessionWhereUniqueInput
    data: XOR<UserSessionUpdateWithoutUserInput, UserSessionUncheckedUpdateWithoutUserInput>
  }

  export type UserSessionUpdateManyWithWhereWithoutUserInput = {
    where: UserSessionScalarWhereInput
    data: XOR<UserSessionUpdateManyMutationInput, UserSessionUncheckedUpdateManyWithoutUserInput>
  }

  export type UserSessionScalarWhereInput = {
    AND?: UserSessionScalarWhereInput | UserSessionScalarWhereInput[]
    OR?: UserSessionScalarWhereInput[]
    NOT?: UserSessionScalarWhereInput | UserSessionScalarWhereInput[]
    id?: StringFilter<"UserSession"> | string
    createdAt?: DateTimeFilter<"UserSession"> | Date | string
    userId?: StringFilter<"UserSession"> | string
    tokenId?: StringFilter<"UserSession"> | string
    refreshTokenHash?: StringFilter<"UserSession"> | string
    deviceInfo?: StringNullableFilter<"UserSession"> | string | null
    ipAddress?: StringNullableFilter<"UserSession"> | string | null
    expiresAt?: DateTimeFilter<"UserSession"> | Date | string
    revokedAt?: DateTimeNullableFilter<"UserSession"> | Date | string | null
  }

  export type UserCreateWithoutSessionsInput = {
    id?: string
    createdAt?: Date | string
    updatedAt?: Date | string
    firstName: string
    lastName: string
    email: string
    phoneNumber: string
    passwordHash: string
    role?: $Enums.Role
    status?: $Enums.UserStatus
    isPhoneVerified?: boolean
    pointsBalance?: number
    totalPointsEarned?: number
    totalPointsSpent?: number
    lastActiveAt?: Date | string | null
    reports?: ReportCreateNestedManyWithoutReporterInput
    moderatedReports?: ReportCreateNestedManyWithoutModeratedByInput
    adminNotifications?: AdminNotificationCreateNestedManyWithoutUserInput
    pointTransactions?: PointTransactionCreateNestedManyWithoutUserInput
    coReportedReports?: ReportCoReporterCreateNestedManyWithoutUserInput
  }

  export type UserUncheckedCreateWithoutSessionsInput = {
    id?: string
    createdAt?: Date | string
    updatedAt?: Date | string
    firstName: string
    lastName: string
    email: string
    phoneNumber: string
    passwordHash: string
    role?: $Enums.Role
    status?: $Enums.UserStatus
    isPhoneVerified?: boolean
    pointsBalance?: number
    totalPointsEarned?: number
    totalPointsSpent?: number
    lastActiveAt?: Date | string | null
    reports?: ReportUncheckedCreateNestedManyWithoutReporterInput
    moderatedReports?: ReportUncheckedCreateNestedManyWithoutModeratedByInput
    adminNotifications?: AdminNotificationUncheckedCreateNestedManyWithoutUserInput
    pointTransactions?: PointTransactionUncheckedCreateNestedManyWithoutUserInput
    coReportedReports?: ReportCoReporterUncheckedCreateNestedManyWithoutUserInput
  }

  export type UserCreateOrConnectWithoutSessionsInput = {
    where: UserWhereUniqueInput
    create: XOR<UserCreateWithoutSessionsInput, UserUncheckedCreateWithoutSessionsInput>
  }

  export type UserUpsertWithoutSessionsInput = {
    update: XOR<UserUpdateWithoutSessionsInput, UserUncheckedUpdateWithoutSessionsInput>
    create: XOR<UserCreateWithoutSessionsInput, UserUncheckedCreateWithoutSessionsInput>
    where?: UserWhereInput
  }

  export type UserUpdateToOneWithWhereWithoutSessionsInput = {
    where?: UserWhereInput
    data: XOR<UserUpdateWithoutSessionsInput, UserUncheckedUpdateWithoutSessionsInput>
  }

  export type UserUpdateWithoutSessionsInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    updatedAt?: DateTimeFieldUpdateOperationsInput | Date | string
    firstName?: StringFieldUpdateOperationsInput | string
    lastName?: StringFieldUpdateOperationsInput | string
    email?: StringFieldUpdateOperationsInput | string
    phoneNumber?: StringFieldUpdateOperationsInput | string
    passwordHash?: StringFieldUpdateOperationsInput | string
    role?: EnumRoleFieldUpdateOperationsInput | $Enums.Role
    status?: EnumUserStatusFieldUpdateOperationsInput | $Enums.UserStatus
    isPhoneVerified?: BoolFieldUpdateOperationsInput | boolean
    pointsBalance?: IntFieldUpdateOperationsInput | number
    totalPointsEarned?: IntFieldUpdateOperationsInput | number
    totalPointsSpent?: IntFieldUpdateOperationsInput | number
    lastActiveAt?: NullableDateTimeFieldUpdateOperationsInput | Date | string | null
    reports?: ReportUpdateManyWithoutReporterNestedInput
    moderatedReports?: ReportUpdateManyWithoutModeratedByNestedInput
    adminNotifications?: AdminNotificationUpdateManyWithoutUserNestedInput
    pointTransactions?: PointTransactionUpdateManyWithoutUserNestedInput
    coReportedReports?: ReportCoReporterUpdateManyWithoutUserNestedInput
  }

  export type UserUncheckedUpdateWithoutSessionsInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    updatedAt?: DateTimeFieldUpdateOperationsInput | Date | string
    firstName?: StringFieldUpdateOperationsInput | string
    lastName?: StringFieldUpdateOperationsInput | string
    email?: StringFieldUpdateOperationsInput | string
    phoneNumber?: StringFieldUpdateOperationsInput | string
    passwordHash?: StringFieldUpdateOperationsInput | string
    role?: EnumRoleFieldUpdateOperationsInput | $Enums.Role
    status?: EnumUserStatusFieldUpdateOperationsInput | $Enums.UserStatus
    isPhoneVerified?: BoolFieldUpdateOperationsInput | boolean
    pointsBalance?: IntFieldUpdateOperationsInput | number
    totalPointsEarned?: IntFieldUpdateOperationsInput | number
    totalPointsSpent?: IntFieldUpdateOperationsInput | number
    lastActiveAt?: NullableDateTimeFieldUpdateOperationsInput | Date | string | null
    reports?: ReportUncheckedUpdateManyWithoutReporterNestedInput
    moderatedReports?: ReportUncheckedUpdateManyWithoutModeratedByNestedInput
    adminNotifications?: AdminNotificationUncheckedUpdateManyWithoutUserNestedInput
    pointTransactions?: PointTransactionUncheckedUpdateManyWithoutUserNestedInput
    coReportedReports?: ReportCoReporterUncheckedUpdateManyWithoutUserNestedInput
  }

  export type UserCreateWithoutAdminNotificationsInput = {
    id?: string
    createdAt?: Date | string
    updatedAt?: Date | string
    firstName: string
    lastName: string
    email: string
    phoneNumber: string
    passwordHash: string
    role?: $Enums.Role
    status?: $Enums.UserStatus
    isPhoneVerified?: boolean
    pointsBalance?: number
    totalPointsEarned?: number
    totalPointsSpent?: number
    lastActiveAt?: Date | string | null
    reports?: ReportCreateNestedManyWithoutReporterInput
    moderatedReports?: ReportCreateNestedManyWithoutModeratedByInput
    pointTransactions?: PointTransactionCreateNestedManyWithoutUserInput
    coReportedReports?: ReportCoReporterCreateNestedManyWithoutUserInput
    sessions?: UserSessionCreateNestedManyWithoutUserInput
  }

  export type UserUncheckedCreateWithoutAdminNotificationsInput = {
    id?: string
    createdAt?: Date | string
    updatedAt?: Date | string
    firstName: string
    lastName: string
    email: string
    phoneNumber: string
    passwordHash: string
    role?: $Enums.Role
    status?: $Enums.UserStatus
    isPhoneVerified?: boolean
    pointsBalance?: number
    totalPointsEarned?: number
    totalPointsSpent?: number
    lastActiveAt?: Date | string | null
    reports?: ReportUncheckedCreateNestedManyWithoutReporterInput
    moderatedReports?: ReportUncheckedCreateNestedManyWithoutModeratedByInput
    pointTransactions?: PointTransactionUncheckedCreateNestedManyWithoutUserInput
    coReportedReports?: ReportCoReporterUncheckedCreateNestedManyWithoutUserInput
    sessions?: UserSessionUncheckedCreateNestedManyWithoutUserInput
  }

  export type UserCreateOrConnectWithoutAdminNotificationsInput = {
    where: UserWhereUniqueInput
    create: XOR<UserCreateWithoutAdminNotificationsInput, UserUncheckedCreateWithoutAdminNotificationsInput>
  }

  export type UserUpsertWithoutAdminNotificationsInput = {
    update: XOR<UserUpdateWithoutAdminNotificationsInput, UserUncheckedUpdateWithoutAdminNotificationsInput>
    create: XOR<UserCreateWithoutAdminNotificationsInput, UserUncheckedCreateWithoutAdminNotificationsInput>
    where?: UserWhereInput
  }

  export type UserUpdateToOneWithWhereWithoutAdminNotificationsInput = {
    where?: UserWhereInput
    data: XOR<UserUpdateWithoutAdminNotificationsInput, UserUncheckedUpdateWithoutAdminNotificationsInput>
  }

  export type UserUpdateWithoutAdminNotificationsInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    updatedAt?: DateTimeFieldUpdateOperationsInput | Date | string
    firstName?: StringFieldUpdateOperationsInput | string
    lastName?: StringFieldUpdateOperationsInput | string
    email?: StringFieldUpdateOperationsInput | string
    phoneNumber?: StringFieldUpdateOperationsInput | string
    passwordHash?: StringFieldUpdateOperationsInput | string
    role?: EnumRoleFieldUpdateOperationsInput | $Enums.Role
    status?: EnumUserStatusFieldUpdateOperationsInput | $Enums.UserStatus
    isPhoneVerified?: BoolFieldUpdateOperationsInput | boolean
    pointsBalance?: IntFieldUpdateOperationsInput | number
    totalPointsEarned?: IntFieldUpdateOperationsInput | number
    totalPointsSpent?: IntFieldUpdateOperationsInput | number
    lastActiveAt?: NullableDateTimeFieldUpdateOperationsInput | Date | string | null
    reports?: ReportUpdateManyWithoutReporterNestedInput
    moderatedReports?: ReportUpdateManyWithoutModeratedByNestedInput
    pointTransactions?: PointTransactionUpdateManyWithoutUserNestedInput
    coReportedReports?: ReportCoReporterUpdateManyWithoutUserNestedInput
    sessions?: UserSessionUpdateManyWithoutUserNestedInput
  }

  export type UserUncheckedUpdateWithoutAdminNotificationsInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    updatedAt?: DateTimeFieldUpdateOperationsInput | Date | string
    firstName?: StringFieldUpdateOperationsInput | string
    lastName?: StringFieldUpdateOperationsInput | string
    email?: StringFieldUpdateOperationsInput | string
    phoneNumber?: StringFieldUpdateOperationsInput | string
    passwordHash?: StringFieldUpdateOperationsInput | string
    role?: EnumRoleFieldUpdateOperationsInput | $Enums.Role
    status?: EnumUserStatusFieldUpdateOperationsInput | $Enums.UserStatus
    isPhoneVerified?: BoolFieldUpdateOperationsInput | boolean
    pointsBalance?: IntFieldUpdateOperationsInput | number
    totalPointsEarned?: IntFieldUpdateOperationsInput | number
    totalPointsSpent?: IntFieldUpdateOperationsInput | number
    lastActiveAt?: NullableDateTimeFieldUpdateOperationsInput | Date | string | null
    reports?: ReportUncheckedUpdateManyWithoutReporterNestedInput
    moderatedReports?: ReportUncheckedUpdateManyWithoutModeratedByNestedInput
    pointTransactions?: PointTransactionUncheckedUpdateManyWithoutUserNestedInput
    coReportedReports?: ReportCoReporterUncheckedUpdateManyWithoutUserNestedInput
    sessions?: UserSessionUncheckedUpdateManyWithoutUserNestedInput
  }

  export type UserCreateWithoutPointTransactionsInput = {
    id?: string
    createdAt?: Date | string
    updatedAt?: Date | string
    firstName: string
    lastName: string
    email: string
    phoneNumber: string
    passwordHash: string
    role?: $Enums.Role
    status?: $Enums.UserStatus
    isPhoneVerified?: boolean
    pointsBalance?: number
    totalPointsEarned?: number
    totalPointsSpent?: number
    lastActiveAt?: Date | string | null
    reports?: ReportCreateNestedManyWithoutReporterInput
    moderatedReports?: ReportCreateNestedManyWithoutModeratedByInput
    adminNotifications?: AdminNotificationCreateNestedManyWithoutUserInput
    coReportedReports?: ReportCoReporterCreateNestedManyWithoutUserInput
    sessions?: UserSessionCreateNestedManyWithoutUserInput
  }

  export type UserUncheckedCreateWithoutPointTransactionsInput = {
    id?: string
    createdAt?: Date | string
    updatedAt?: Date | string
    firstName: string
    lastName: string
    email: string
    phoneNumber: string
    passwordHash: string
    role?: $Enums.Role
    status?: $Enums.UserStatus
    isPhoneVerified?: boolean
    pointsBalance?: number
    totalPointsEarned?: number
    totalPointsSpent?: number
    lastActiveAt?: Date | string | null
    reports?: ReportUncheckedCreateNestedManyWithoutReporterInput
    moderatedReports?: ReportUncheckedCreateNestedManyWithoutModeratedByInput
    adminNotifications?: AdminNotificationUncheckedCreateNestedManyWithoutUserInput
    coReportedReports?: ReportCoReporterUncheckedCreateNestedManyWithoutUserInput
    sessions?: UserSessionUncheckedCreateNestedManyWithoutUserInput
  }

  export type UserCreateOrConnectWithoutPointTransactionsInput = {
    where: UserWhereUniqueInput
    create: XOR<UserCreateWithoutPointTransactionsInput, UserUncheckedCreateWithoutPointTransactionsInput>
  }

  export type UserUpsertWithoutPointTransactionsInput = {
    update: XOR<UserUpdateWithoutPointTransactionsInput, UserUncheckedUpdateWithoutPointTransactionsInput>
    create: XOR<UserCreateWithoutPointTransactionsInput, UserUncheckedCreateWithoutPointTransactionsInput>
    where?: UserWhereInput
  }

  export type UserUpdateToOneWithWhereWithoutPointTransactionsInput = {
    where?: UserWhereInput
    data: XOR<UserUpdateWithoutPointTransactionsInput, UserUncheckedUpdateWithoutPointTransactionsInput>
  }

  export type UserUpdateWithoutPointTransactionsInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    updatedAt?: DateTimeFieldUpdateOperationsInput | Date | string
    firstName?: StringFieldUpdateOperationsInput | string
    lastName?: StringFieldUpdateOperationsInput | string
    email?: StringFieldUpdateOperationsInput | string
    phoneNumber?: StringFieldUpdateOperationsInput | string
    passwordHash?: StringFieldUpdateOperationsInput | string
    role?: EnumRoleFieldUpdateOperationsInput | $Enums.Role
    status?: EnumUserStatusFieldUpdateOperationsInput | $Enums.UserStatus
    isPhoneVerified?: BoolFieldUpdateOperationsInput | boolean
    pointsBalance?: IntFieldUpdateOperationsInput | number
    totalPointsEarned?: IntFieldUpdateOperationsInput | number
    totalPointsSpent?: IntFieldUpdateOperationsInput | number
    lastActiveAt?: NullableDateTimeFieldUpdateOperationsInput | Date | string | null
    reports?: ReportUpdateManyWithoutReporterNestedInput
    moderatedReports?: ReportUpdateManyWithoutModeratedByNestedInput
    adminNotifications?: AdminNotificationUpdateManyWithoutUserNestedInput
    coReportedReports?: ReportCoReporterUpdateManyWithoutUserNestedInput
    sessions?: UserSessionUpdateManyWithoutUserNestedInput
  }

  export type UserUncheckedUpdateWithoutPointTransactionsInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    updatedAt?: DateTimeFieldUpdateOperationsInput | Date | string
    firstName?: StringFieldUpdateOperationsInput | string
    lastName?: StringFieldUpdateOperationsInput | string
    email?: StringFieldUpdateOperationsInput | string
    phoneNumber?: StringFieldUpdateOperationsInput | string
    passwordHash?: StringFieldUpdateOperationsInput | string
    role?: EnumRoleFieldUpdateOperationsInput | $Enums.Role
    status?: EnumUserStatusFieldUpdateOperationsInput | $Enums.UserStatus
    isPhoneVerified?: BoolFieldUpdateOperationsInput | boolean
    pointsBalance?: IntFieldUpdateOperationsInput | number
    totalPointsEarned?: IntFieldUpdateOperationsInput | number
    totalPointsSpent?: IntFieldUpdateOperationsInput | number
    lastActiveAt?: NullableDateTimeFieldUpdateOperationsInput | Date | string | null
    reports?: ReportUncheckedUpdateManyWithoutReporterNestedInput
    moderatedReports?: ReportUncheckedUpdateManyWithoutModeratedByNestedInput
    adminNotifications?: AdminNotificationUncheckedUpdateManyWithoutUserNestedInput
    coReportedReports?: ReportCoReporterUncheckedUpdateManyWithoutUserNestedInput
    sessions?: UserSessionUncheckedUpdateManyWithoutUserNestedInput
  }

  export type ReportCreateWithoutSiteInput = {
    id?: string
    createdAt?: Date | string
    reportNumber?: string | null
    description?: string | null
    mediaUrls?: ReportCreatemediaUrlsInput | string[]
    category?: string | null
    severity?: number | null
    status?: $Enums.ReportStatus
    moderatedAt?: Date | string | null
    moderationReason?: string | null
    reporter?: UserCreateNestedOneWithoutReportsInput
    moderatedBy?: UserCreateNestedOneWithoutModeratedReportsInput
    potentialDuplicateOf?: ReportCreateNestedOneWithoutPotentialDuplicatesInput
    potentialDuplicates?: ReportCreateNestedManyWithoutPotentialDuplicateOfInput
    coReporters?: ReportCoReporterCreateNestedManyWithoutReportInput
  }

  export type ReportUncheckedCreateWithoutSiteInput = {
    id?: string
    createdAt?: Date | string
    reportNumber?: string | null
    reporterId?: string | null
    description?: string | null
    mediaUrls?: ReportCreatemediaUrlsInput | string[]
    category?: string | null
    severity?: number | null
    status?: $Enums.ReportStatus
    moderatedAt?: Date | string | null
    moderationReason?: string | null
    moderatedById?: string | null
    potentialDuplicateOfId?: string | null
    potentialDuplicates?: ReportUncheckedCreateNestedManyWithoutPotentialDuplicateOfInput
    coReporters?: ReportCoReporterUncheckedCreateNestedManyWithoutReportInput
  }

  export type ReportCreateOrConnectWithoutSiteInput = {
    where: ReportWhereUniqueInput
    create: XOR<ReportCreateWithoutSiteInput, ReportUncheckedCreateWithoutSiteInput>
  }

  export type ReportCreateManySiteInputEnvelope = {
    data: ReportCreateManySiteInput | ReportCreateManySiteInput[]
    skipDuplicates?: boolean
  }

  export type CleanupEventCreateWithoutSiteInput = {
    id?: string
    createdAt?: Date | string
    updatedAt?: Date | string
    scheduledAt: Date | string
    completedAt?: Date | string | null
    organizerId?: string | null
    participantCount?: number
  }

  export type CleanupEventUncheckedCreateWithoutSiteInput = {
    id?: string
    createdAt?: Date | string
    updatedAt?: Date | string
    scheduledAt: Date | string
    completedAt?: Date | string | null
    organizerId?: string | null
    participantCount?: number
  }

  export type CleanupEventCreateOrConnectWithoutSiteInput = {
    where: CleanupEventWhereUniqueInput
    create: XOR<CleanupEventCreateWithoutSiteInput, CleanupEventUncheckedCreateWithoutSiteInput>
  }

  export type CleanupEventCreateManySiteInputEnvelope = {
    data: CleanupEventCreateManySiteInput | CleanupEventCreateManySiteInput[]
    skipDuplicates?: boolean
  }

  export type ReportUpsertWithWhereUniqueWithoutSiteInput = {
    where: ReportWhereUniqueInput
    update: XOR<ReportUpdateWithoutSiteInput, ReportUncheckedUpdateWithoutSiteInput>
    create: XOR<ReportCreateWithoutSiteInput, ReportUncheckedCreateWithoutSiteInput>
  }

  export type ReportUpdateWithWhereUniqueWithoutSiteInput = {
    where: ReportWhereUniqueInput
    data: XOR<ReportUpdateWithoutSiteInput, ReportUncheckedUpdateWithoutSiteInput>
  }

  export type ReportUpdateManyWithWhereWithoutSiteInput = {
    where: ReportScalarWhereInput
    data: XOR<ReportUpdateManyMutationInput, ReportUncheckedUpdateManyWithoutSiteInput>
  }

  export type CleanupEventUpsertWithWhereUniqueWithoutSiteInput = {
    where: CleanupEventWhereUniqueInput
    update: XOR<CleanupEventUpdateWithoutSiteInput, CleanupEventUncheckedUpdateWithoutSiteInput>
    create: XOR<CleanupEventCreateWithoutSiteInput, CleanupEventUncheckedCreateWithoutSiteInput>
  }

  export type CleanupEventUpdateWithWhereUniqueWithoutSiteInput = {
    where: CleanupEventWhereUniqueInput
    data: XOR<CleanupEventUpdateWithoutSiteInput, CleanupEventUncheckedUpdateWithoutSiteInput>
  }

  export type CleanupEventUpdateManyWithWhereWithoutSiteInput = {
    where: CleanupEventScalarWhereInput
    data: XOR<CleanupEventUpdateManyMutationInput, CleanupEventUncheckedUpdateManyWithoutSiteInput>
  }

  export type CleanupEventScalarWhereInput = {
    AND?: CleanupEventScalarWhereInput | CleanupEventScalarWhereInput[]
    OR?: CleanupEventScalarWhereInput[]
    NOT?: CleanupEventScalarWhereInput | CleanupEventScalarWhereInput[]
    id?: StringFilter<"CleanupEvent"> | string
    createdAt?: DateTimeFilter<"CleanupEvent"> | Date | string
    updatedAt?: DateTimeFilter<"CleanupEvent"> | Date | string
    siteId?: StringFilter<"CleanupEvent"> | string
    scheduledAt?: DateTimeFilter<"CleanupEvent"> | Date | string
    completedAt?: DateTimeNullableFilter<"CleanupEvent"> | Date | string | null
    organizerId?: StringNullableFilter<"CleanupEvent"> | string | null
    participantCount?: IntFilter<"CleanupEvent"> | number
  }

  export type SiteCreateWithoutReportsInput = {
    id?: string
    createdAt?: Date | string
    updatedAt?: Date | string
    latitude: number
    longitude: number
    description?: string | null
    status?: $Enums.SiteStatus
    events?: CleanupEventCreateNestedManyWithoutSiteInput
  }

  export type SiteUncheckedCreateWithoutReportsInput = {
    id?: string
    createdAt?: Date | string
    updatedAt?: Date | string
    latitude: number
    longitude: number
    description?: string | null
    status?: $Enums.SiteStatus
    events?: CleanupEventUncheckedCreateNestedManyWithoutSiteInput
  }

  export type SiteCreateOrConnectWithoutReportsInput = {
    where: SiteWhereUniqueInput
    create: XOR<SiteCreateWithoutReportsInput, SiteUncheckedCreateWithoutReportsInput>
  }

  export type UserCreateWithoutReportsInput = {
    id?: string
    createdAt?: Date | string
    updatedAt?: Date | string
    firstName: string
    lastName: string
    email: string
    phoneNumber: string
    passwordHash: string
    role?: $Enums.Role
    status?: $Enums.UserStatus
    isPhoneVerified?: boolean
    pointsBalance?: number
    totalPointsEarned?: number
    totalPointsSpent?: number
    lastActiveAt?: Date | string | null
    moderatedReports?: ReportCreateNestedManyWithoutModeratedByInput
    adminNotifications?: AdminNotificationCreateNestedManyWithoutUserInput
    pointTransactions?: PointTransactionCreateNestedManyWithoutUserInput
    coReportedReports?: ReportCoReporterCreateNestedManyWithoutUserInput
    sessions?: UserSessionCreateNestedManyWithoutUserInput
  }

  export type UserUncheckedCreateWithoutReportsInput = {
    id?: string
    createdAt?: Date | string
    updatedAt?: Date | string
    firstName: string
    lastName: string
    email: string
    phoneNumber: string
    passwordHash: string
    role?: $Enums.Role
    status?: $Enums.UserStatus
    isPhoneVerified?: boolean
    pointsBalance?: number
    totalPointsEarned?: number
    totalPointsSpent?: number
    lastActiveAt?: Date | string | null
    moderatedReports?: ReportUncheckedCreateNestedManyWithoutModeratedByInput
    adminNotifications?: AdminNotificationUncheckedCreateNestedManyWithoutUserInput
    pointTransactions?: PointTransactionUncheckedCreateNestedManyWithoutUserInput
    coReportedReports?: ReportCoReporterUncheckedCreateNestedManyWithoutUserInput
    sessions?: UserSessionUncheckedCreateNestedManyWithoutUserInput
  }

  export type UserCreateOrConnectWithoutReportsInput = {
    where: UserWhereUniqueInput
    create: XOR<UserCreateWithoutReportsInput, UserUncheckedCreateWithoutReportsInput>
  }

  export type UserCreateWithoutModeratedReportsInput = {
    id?: string
    createdAt?: Date | string
    updatedAt?: Date | string
    firstName: string
    lastName: string
    email: string
    phoneNumber: string
    passwordHash: string
    role?: $Enums.Role
    status?: $Enums.UserStatus
    isPhoneVerified?: boolean
    pointsBalance?: number
    totalPointsEarned?: number
    totalPointsSpent?: number
    lastActiveAt?: Date | string | null
    reports?: ReportCreateNestedManyWithoutReporterInput
    adminNotifications?: AdminNotificationCreateNestedManyWithoutUserInput
    pointTransactions?: PointTransactionCreateNestedManyWithoutUserInput
    coReportedReports?: ReportCoReporterCreateNestedManyWithoutUserInput
    sessions?: UserSessionCreateNestedManyWithoutUserInput
  }

  export type UserUncheckedCreateWithoutModeratedReportsInput = {
    id?: string
    createdAt?: Date | string
    updatedAt?: Date | string
    firstName: string
    lastName: string
    email: string
    phoneNumber: string
    passwordHash: string
    role?: $Enums.Role
    status?: $Enums.UserStatus
    isPhoneVerified?: boolean
    pointsBalance?: number
    totalPointsEarned?: number
    totalPointsSpent?: number
    lastActiveAt?: Date | string | null
    reports?: ReportUncheckedCreateNestedManyWithoutReporterInput
    adminNotifications?: AdminNotificationUncheckedCreateNestedManyWithoutUserInput
    pointTransactions?: PointTransactionUncheckedCreateNestedManyWithoutUserInput
    coReportedReports?: ReportCoReporterUncheckedCreateNestedManyWithoutUserInput
    sessions?: UserSessionUncheckedCreateNestedManyWithoutUserInput
  }

  export type UserCreateOrConnectWithoutModeratedReportsInput = {
    where: UserWhereUniqueInput
    create: XOR<UserCreateWithoutModeratedReportsInput, UserUncheckedCreateWithoutModeratedReportsInput>
  }

  export type ReportCreateWithoutPotentialDuplicatesInput = {
    id?: string
    createdAt?: Date | string
    reportNumber?: string | null
    description?: string | null
    mediaUrls?: ReportCreatemediaUrlsInput | string[]
    category?: string | null
    severity?: number | null
    status?: $Enums.ReportStatus
    moderatedAt?: Date | string | null
    moderationReason?: string | null
    site: SiteCreateNestedOneWithoutReportsInput
    reporter?: UserCreateNestedOneWithoutReportsInput
    moderatedBy?: UserCreateNestedOneWithoutModeratedReportsInput
    potentialDuplicateOf?: ReportCreateNestedOneWithoutPotentialDuplicatesInput
    coReporters?: ReportCoReporterCreateNestedManyWithoutReportInput
  }

  export type ReportUncheckedCreateWithoutPotentialDuplicatesInput = {
    id?: string
    createdAt?: Date | string
    reportNumber?: string | null
    siteId: string
    reporterId?: string | null
    description?: string | null
    mediaUrls?: ReportCreatemediaUrlsInput | string[]
    category?: string | null
    severity?: number | null
    status?: $Enums.ReportStatus
    moderatedAt?: Date | string | null
    moderationReason?: string | null
    moderatedById?: string | null
    potentialDuplicateOfId?: string | null
    coReporters?: ReportCoReporterUncheckedCreateNestedManyWithoutReportInput
  }

  export type ReportCreateOrConnectWithoutPotentialDuplicatesInput = {
    where: ReportWhereUniqueInput
    create: XOR<ReportCreateWithoutPotentialDuplicatesInput, ReportUncheckedCreateWithoutPotentialDuplicatesInput>
  }

  export type ReportCreateWithoutPotentialDuplicateOfInput = {
    id?: string
    createdAt?: Date | string
    reportNumber?: string | null
    description?: string | null
    mediaUrls?: ReportCreatemediaUrlsInput | string[]
    category?: string | null
    severity?: number | null
    status?: $Enums.ReportStatus
    moderatedAt?: Date | string | null
    moderationReason?: string | null
    site: SiteCreateNestedOneWithoutReportsInput
    reporter?: UserCreateNestedOneWithoutReportsInput
    moderatedBy?: UserCreateNestedOneWithoutModeratedReportsInput
    potentialDuplicates?: ReportCreateNestedManyWithoutPotentialDuplicateOfInput
    coReporters?: ReportCoReporterCreateNestedManyWithoutReportInput
  }

  export type ReportUncheckedCreateWithoutPotentialDuplicateOfInput = {
    id?: string
    createdAt?: Date | string
    reportNumber?: string | null
    siteId: string
    reporterId?: string | null
    description?: string | null
    mediaUrls?: ReportCreatemediaUrlsInput | string[]
    category?: string | null
    severity?: number | null
    status?: $Enums.ReportStatus
    moderatedAt?: Date | string | null
    moderationReason?: string | null
    moderatedById?: string | null
    potentialDuplicates?: ReportUncheckedCreateNestedManyWithoutPotentialDuplicateOfInput
    coReporters?: ReportCoReporterUncheckedCreateNestedManyWithoutReportInput
  }

  export type ReportCreateOrConnectWithoutPotentialDuplicateOfInput = {
    where: ReportWhereUniqueInput
    create: XOR<ReportCreateWithoutPotentialDuplicateOfInput, ReportUncheckedCreateWithoutPotentialDuplicateOfInput>
  }

  export type ReportCreateManyPotentialDuplicateOfInputEnvelope = {
    data: ReportCreateManyPotentialDuplicateOfInput | ReportCreateManyPotentialDuplicateOfInput[]
    skipDuplicates?: boolean
  }

  export type ReportCoReporterCreateWithoutReportInput = {
    id?: string
    createdAt?: Date | string
    user: UserCreateNestedOneWithoutCoReportedReportsInput
  }

  export type ReportCoReporterUncheckedCreateWithoutReportInput = {
    id?: string
    createdAt?: Date | string
    userId: string
  }

  export type ReportCoReporterCreateOrConnectWithoutReportInput = {
    where: ReportCoReporterWhereUniqueInput
    create: XOR<ReportCoReporterCreateWithoutReportInput, ReportCoReporterUncheckedCreateWithoutReportInput>
  }

  export type ReportCoReporterCreateManyReportInputEnvelope = {
    data: ReportCoReporterCreateManyReportInput | ReportCoReporterCreateManyReportInput[]
    skipDuplicates?: boolean
  }

  export type SiteUpsertWithoutReportsInput = {
    update: XOR<SiteUpdateWithoutReportsInput, SiteUncheckedUpdateWithoutReportsInput>
    create: XOR<SiteCreateWithoutReportsInput, SiteUncheckedCreateWithoutReportsInput>
    where?: SiteWhereInput
  }

  export type SiteUpdateToOneWithWhereWithoutReportsInput = {
    where?: SiteWhereInput
    data: XOR<SiteUpdateWithoutReportsInput, SiteUncheckedUpdateWithoutReportsInput>
  }

  export type SiteUpdateWithoutReportsInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    updatedAt?: DateTimeFieldUpdateOperationsInput | Date | string
    latitude?: FloatFieldUpdateOperationsInput | number
    longitude?: FloatFieldUpdateOperationsInput | number
    description?: NullableStringFieldUpdateOperationsInput | string | null
    status?: EnumSiteStatusFieldUpdateOperationsInput | $Enums.SiteStatus
    events?: CleanupEventUpdateManyWithoutSiteNestedInput
  }

  export type SiteUncheckedUpdateWithoutReportsInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    updatedAt?: DateTimeFieldUpdateOperationsInput | Date | string
    latitude?: FloatFieldUpdateOperationsInput | number
    longitude?: FloatFieldUpdateOperationsInput | number
    description?: NullableStringFieldUpdateOperationsInput | string | null
    status?: EnumSiteStatusFieldUpdateOperationsInput | $Enums.SiteStatus
    events?: CleanupEventUncheckedUpdateManyWithoutSiteNestedInput
  }

  export type UserUpsertWithoutReportsInput = {
    update: XOR<UserUpdateWithoutReportsInput, UserUncheckedUpdateWithoutReportsInput>
    create: XOR<UserCreateWithoutReportsInput, UserUncheckedCreateWithoutReportsInput>
    where?: UserWhereInput
  }

  export type UserUpdateToOneWithWhereWithoutReportsInput = {
    where?: UserWhereInput
    data: XOR<UserUpdateWithoutReportsInput, UserUncheckedUpdateWithoutReportsInput>
  }

  export type UserUpdateWithoutReportsInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    updatedAt?: DateTimeFieldUpdateOperationsInput | Date | string
    firstName?: StringFieldUpdateOperationsInput | string
    lastName?: StringFieldUpdateOperationsInput | string
    email?: StringFieldUpdateOperationsInput | string
    phoneNumber?: StringFieldUpdateOperationsInput | string
    passwordHash?: StringFieldUpdateOperationsInput | string
    role?: EnumRoleFieldUpdateOperationsInput | $Enums.Role
    status?: EnumUserStatusFieldUpdateOperationsInput | $Enums.UserStatus
    isPhoneVerified?: BoolFieldUpdateOperationsInput | boolean
    pointsBalance?: IntFieldUpdateOperationsInput | number
    totalPointsEarned?: IntFieldUpdateOperationsInput | number
    totalPointsSpent?: IntFieldUpdateOperationsInput | number
    lastActiveAt?: NullableDateTimeFieldUpdateOperationsInput | Date | string | null
    moderatedReports?: ReportUpdateManyWithoutModeratedByNestedInput
    adminNotifications?: AdminNotificationUpdateManyWithoutUserNestedInput
    pointTransactions?: PointTransactionUpdateManyWithoutUserNestedInput
    coReportedReports?: ReportCoReporterUpdateManyWithoutUserNestedInput
    sessions?: UserSessionUpdateManyWithoutUserNestedInput
  }

  export type UserUncheckedUpdateWithoutReportsInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    updatedAt?: DateTimeFieldUpdateOperationsInput | Date | string
    firstName?: StringFieldUpdateOperationsInput | string
    lastName?: StringFieldUpdateOperationsInput | string
    email?: StringFieldUpdateOperationsInput | string
    phoneNumber?: StringFieldUpdateOperationsInput | string
    passwordHash?: StringFieldUpdateOperationsInput | string
    role?: EnumRoleFieldUpdateOperationsInput | $Enums.Role
    status?: EnumUserStatusFieldUpdateOperationsInput | $Enums.UserStatus
    isPhoneVerified?: BoolFieldUpdateOperationsInput | boolean
    pointsBalance?: IntFieldUpdateOperationsInput | number
    totalPointsEarned?: IntFieldUpdateOperationsInput | number
    totalPointsSpent?: IntFieldUpdateOperationsInput | number
    lastActiveAt?: NullableDateTimeFieldUpdateOperationsInput | Date | string | null
    moderatedReports?: ReportUncheckedUpdateManyWithoutModeratedByNestedInput
    adminNotifications?: AdminNotificationUncheckedUpdateManyWithoutUserNestedInput
    pointTransactions?: PointTransactionUncheckedUpdateManyWithoutUserNestedInput
    coReportedReports?: ReportCoReporterUncheckedUpdateManyWithoutUserNestedInput
    sessions?: UserSessionUncheckedUpdateManyWithoutUserNestedInput
  }

  export type UserUpsertWithoutModeratedReportsInput = {
    update: XOR<UserUpdateWithoutModeratedReportsInput, UserUncheckedUpdateWithoutModeratedReportsInput>
    create: XOR<UserCreateWithoutModeratedReportsInput, UserUncheckedCreateWithoutModeratedReportsInput>
    where?: UserWhereInput
  }

  export type UserUpdateToOneWithWhereWithoutModeratedReportsInput = {
    where?: UserWhereInput
    data: XOR<UserUpdateWithoutModeratedReportsInput, UserUncheckedUpdateWithoutModeratedReportsInput>
  }

  export type UserUpdateWithoutModeratedReportsInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    updatedAt?: DateTimeFieldUpdateOperationsInput | Date | string
    firstName?: StringFieldUpdateOperationsInput | string
    lastName?: StringFieldUpdateOperationsInput | string
    email?: StringFieldUpdateOperationsInput | string
    phoneNumber?: StringFieldUpdateOperationsInput | string
    passwordHash?: StringFieldUpdateOperationsInput | string
    role?: EnumRoleFieldUpdateOperationsInput | $Enums.Role
    status?: EnumUserStatusFieldUpdateOperationsInput | $Enums.UserStatus
    isPhoneVerified?: BoolFieldUpdateOperationsInput | boolean
    pointsBalance?: IntFieldUpdateOperationsInput | number
    totalPointsEarned?: IntFieldUpdateOperationsInput | number
    totalPointsSpent?: IntFieldUpdateOperationsInput | number
    lastActiveAt?: NullableDateTimeFieldUpdateOperationsInput | Date | string | null
    reports?: ReportUpdateManyWithoutReporterNestedInput
    adminNotifications?: AdminNotificationUpdateManyWithoutUserNestedInput
    pointTransactions?: PointTransactionUpdateManyWithoutUserNestedInput
    coReportedReports?: ReportCoReporterUpdateManyWithoutUserNestedInput
    sessions?: UserSessionUpdateManyWithoutUserNestedInput
  }

  export type UserUncheckedUpdateWithoutModeratedReportsInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    updatedAt?: DateTimeFieldUpdateOperationsInput | Date | string
    firstName?: StringFieldUpdateOperationsInput | string
    lastName?: StringFieldUpdateOperationsInput | string
    email?: StringFieldUpdateOperationsInput | string
    phoneNumber?: StringFieldUpdateOperationsInput | string
    passwordHash?: StringFieldUpdateOperationsInput | string
    role?: EnumRoleFieldUpdateOperationsInput | $Enums.Role
    status?: EnumUserStatusFieldUpdateOperationsInput | $Enums.UserStatus
    isPhoneVerified?: BoolFieldUpdateOperationsInput | boolean
    pointsBalance?: IntFieldUpdateOperationsInput | number
    totalPointsEarned?: IntFieldUpdateOperationsInput | number
    totalPointsSpent?: IntFieldUpdateOperationsInput | number
    lastActiveAt?: NullableDateTimeFieldUpdateOperationsInput | Date | string | null
    reports?: ReportUncheckedUpdateManyWithoutReporterNestedInput
    adminNotifications?: AdminNotificationUncheckedUpdateManyWithoutUserNestedInput
    pointTransactions?: PointTransactionUncheckedUpdateManyWithoutUserNestedInput
    coReportedReports?: ReportCoReporterUncheckedUpdateManyWithoutUserNestedInput
    sessions?: UserSessionUncheckedUpdateManyWithoutUserNestedInput
  }

  export type ReportUpsertWithoutPotentialDuplicatesInput = {
    update: XOR<ReportUpdateWithoutPotentialDuplicatesInput, ReportUncheckedUpdateWithoutPotentialDuplicatesInput>
    create: XOR<ReportCreateWithoutPotentialDuplicatesInput, ReportUncheckedCreateWithoutPotentialDuplicatesInput>
    where?: ReportWhereInput
  }

  export type ReportUpdateToOneWithWhereWithoutPotentialDuplicatesInput = {
    where?: ReportWhereInput
    data: XOR<ReportUpdateWithoutPotentialDuplicatesInput, ReportUncheckedUpdateWithoutPotentialDuplicatesInput>
  }

  export type ReportUpdateWithoutPotentialDuplicatesInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    reportNumber?: NullableStringFieldUpdateOperationsInput | string | null
    description?: NullableStringFieldUpdateOperationsInput | string | null
    mediaUrls?: ReportUpdatemediaUrlsInput | string[]
    category?: NullableStringFieldUpdateOperationsInput | string | null
    severity?: NullableIntFieldUpdateOperationsInput | number | null
    status?: EnumReportStatusFieldUpdateOperationsInput | $Enums.ReportStatus
    moderatedAt?: NullableDateTimeFieldUpdateOperationsInput | Date | string | null
    moderationReason?: NullableStringFieldUpdateOperationsInput | string | null
    site?: SiteUpdateOneRequiredWithoutReportsNestedInput
    reporter?: UserUpdateOneWithoutReportsNestedInput
    moderatedBy?: UserUpdateOneWithoutModeratedReportsNestedInput
    potentialDuplicateOf?: ReportUpdateOneWithoutPotentialDuplicatesNestedInput
    coReporters?: ReportCoReporterUpdateManyWithoutReportNestedInput
  }

  export type ReportUncheckedUpdateWithoutPotentialDuplicatesInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    reportNumber?: NullableStringFieldUpdateOperationsInput | string | null
    siteId?: StringFieldUpdateOperationsInput | string
    reporterId?: NullableStringFieldUpdateOperationsInput | string | null
    description?: NullableStringFieldUpdateOperationsInput | string | null
    mediaUrls?: ReportUpdatemediaUrlsInput | string[]
    category?: NullableStringFieldUpdateOperationsInput | string | null
    severity?: NullableIntFieldUpdateOperationsInput | number | null
    status?: EnumReportStatusFieldUpdateOperationsInput | $Enums.ReportStatus
    moderatedAt?: NullableDateTimeFieldUpdateOperationsInput | Date | string | null
    moderationReason?: NullableStringFieldUpdateOperationsInput | string | null
    moderatedById?: NullableStringFieldUpdateOperationsInput | string | null
    potentialDuplicateOfId?: NullableStringFieldUpdateOperationsInput | string | null
    coReporters?: ReportCoReporterUncheckedUpdateManyWithoutReportNestedInput
  }

  export type ReportUpsertWithWhereUniqueWithoutPotentialDuplicateOfInput = {
    where: ReportWhereUniqueInput
    update: XOR<ReportUpdateWithoutPotentialDuplicateOfInput, ReportUncheckedUpdateWithoutPotentialDuplicateOfInput>
    create: XOR<ReportCreateWithoutPotentialDuplicateOfInput, ReportUncheckedCreateWithoutPotentialDuplicateOfInput>
  }

  export type ReportUpdateWithWhereUniqueWithoutPotentialDuplicateOfInput = {
    where: ReportWhereUniqueInput
    data: XOR<ReportUpdateWithoutPotentialDuplicateOfInput, ReportUncheckedUpdateWithoutPotentialDuplicateOfInput>
  }

  export type ReportUpdateManyWithWhereWithoutPotentialDuplicateOfInput = {
    where: ReportScalarWhereInput
    data: XOR<ReportUpdateManyMutationInput, ReportUncheckedUpdateManyWithoutPotentialDuplicateOfInput>
  }

  export type ReportCoReporterUpsertWithWhereUniqueWithoutReportInput = {
    where: ReportCoReporterWhereUniqueInput
    update: XOR<ReportCoReporterUpdateWithoutReportInput, ReportCoReporterUncheckedUpdateWithoutReportInput>
    create: XOR<ReportCoReporterCreateWithoutReportInput, ReportCoReporterUncheckedCreateWithoutReportInput>
  }

  export type ReportCoReporterUpdateWithWhereUniqueWithoutReportInput = {
    where: ReportCoReporterWhereUniqueInput
    data: XOR<ReportCoReporterUpdateWithoutReportInput, ReportCoReporterUncheckedUpdateWithoutReportInput>
  }

  export type ReportCoReporterUpdateManyWithWhereWithoutReportInput = {
    where: ReportCoReporterScalarWhereInput
    data: XOR<ReportCoReporterUpdateManyMutationInput, ReportCoReporterUncheckedUpdateManyWithoutReportInput>
  }

  export type ReportCreateWithoutCoReportersInput = {
    id?: string
    createdAt?: Date | string
    reportNumber?: string | null
    description?: string | null
    mediaUrls?: ReportCreatemediaUrlsInput | string[]
    category?: string | null
    severity?: number | null
    status?: $Enums.ReportStatus
    moderatedAt?: Date | string | null
    moderationReason?: string | null
    site: SiteCreateNestedOneWithoutReportsInput
    reporter?: UserCreateNestedOneWithoutReportsInput
    moderatedBy?: UserCreateNestedOneWithoutModeratedReportsInput
    potentialDuplicateOf?: ReportCreateNestedOneWithoutPotentialDuplicatesInput
    potentialDuplicates?: ReportCreateNestedManyWithoutPotentialDuplicateOfInput
  }

  export type ReportUncheckedCreateWithoutCoReportersInput = {
    id?: string
    createdAt?: Date | string
    reportNumber?: string | null
    siteId: string
    reporterId?: string | null
    description?: string | null
    mediaUrls?: ReportCreatemediaUrlsInput | string[]
    category?: string | null
    severity?: number | null
    status?: $Enums.ReportStatus
    moderatedAt?: Date | string | null
    moderationReason?: string | null
    moderatedById?: string | null
    potentialDuplicateOfId?: string | null
    potentialDuplicates?: ReportUncheckedCreateNestedManyWithoutPotentialDuplicateOfInput
  }

  export type ReportCreateOrConnectWithoutCoReportersInput = {
    where: ReportWhereUniqueInput
    create: XOR<ReportCreateWithoutCoReportersInput, ReportUncheckedCreateWithoutCoReportersInput>
  }

  export type UserCreateWithoutCoReportedReportsInput = {
    id?: string
    createdAt?: Date | string
    updatedAt?: Date | string
    firstName: string
    lastName: string
    email: string
    phoneNumber: string
    passwordHash: string
    role?: $Enums.Role
    status?: $Enums.UserStatus
    isPhoneVerified?: boolean
    pointsBalance?: number
    totalPointsEarned?: number
    totalPointsSpent?: number
    lastActiveAt?: Date | string | null
    reports?: ReportCreateNestedManyWithoutReporterInput
    moderatedReports?: ReportCreateNestedManyWithoutModeratedByInput
    adminNotifications?: AdminNotificationCreateNestedManyWithoutUserInput
    pointTransactions?: PointTransactionCreateNestedManyWithoutUserInput
    sessions?: UserSessionCreateNestedManyWithoutUserInput
  }

  export type UserUncheckedCreateWithoutCoReportedReportsInput = {
    id?: string
    createdAt?: Date | string
    updatedAt?: Date | string
    firstName: string
    lastName: string
    email: string
    phoneNumber: string
    passwordHash: string
    role?: $Enums.Role
    status?: $Enums.UserStatus
    isPhoneVerified?: boolean
    pointsBalance?: number
    totalPointsEarned?: number
    totalPointsSpent?: number
    lastActiveAt?: Date | string | null
    reports?: ReportUncheckedCreateNestedManyWithoutReporterInput
    moderatedReports?: ReportUncheckedCreateNestedManyWithoutModeratedByInput
    adminNotifications?: AdminNotificationUncheckedCreateNestedManyWithoutUserInput
    pointTransactions?: PointTransactionUncheckedCreateNestedManyWithoutUserInput
    sessions?: UserSessionUncheckedCreateNestedManyWithoutUserInput
  }

  export type UserCreateOrConnectWithoutCoReportedReportsInput = {
    where: UserWhereUniqueInput
    create: XOR<UserCreateWithoutCoReportedReportsInput, UserUncheckedCreateWithoutCoReportedReportsInput>
  }

  export type ReportUpsertWithoutCoReportersInput = {
    update: XOR<ReportUpdateWithoutCoReportersInput, ReportUncheckedUpdateWithoutCoReportersInput>
    create: XOR<ReportCreateWithoutCoReportersInput, ReportUncheckedCreateWithoutCoReportersInput>
    where?: ReportWhereInput
  }

  export type ReportUpdateToOneWithWhereWithoutCoReportersInput = {
    where?: ReportWhereInput
    data: XOR<ReportUpdateWithoutCoReportersInput, ReportUncheckedUpdateWithoutCoReportersInput>
  }

  export type ReportUpdateWithoutCoReportersInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    reportNumber?: NullableStringFieldUpdateOperationsInput | string | null
    description?: NullableStringFieldUpdateOperationsInput | string | null
    mediaUrls?: ReportUpdatemediaUrlsInput | string[]
    category?: NullableStringFieldUpdateOperationsInput | string | null
    severity?: NullableIntFieldUpdateOperationsInput | number | null
    status?: EnumReportStatusFieldUpdateOperationsInput | $Enums.ReportStatus
    moderatedAt?: NullableDateTimeFieldUpdateOperationsInput | Date | string | null
    moderationReason?: NullableStringFieldUpdateOperationsInput | string | null
    site?: SiteUpdateOneRequiredWithoutReportsNestedInput
    reporter?: UserUpdateOneWithoutReportsNestedInput
    moderatedBy?: UserUpdateOneWithoutModeratedReportsNestedInput
    potentialDuplicateOf?: ReportUpdateOneWithoutPotentialDuplicatesNestedInput
    potentialDuplicates?: ReportUpdateManyWithoutPotentialDuplicateOfNestedInput
  }

  export type ReportUncheckedUpdateWithoutCoReportersInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    reportNumber?: NullableStringFieldUpdateOperationsInput | string | null
    siteId?: StringFieldUpdateOperationsInput | string
    reporterId?: NullableStringFieldUpdateOperationsInput | string | null
    description?: NullableStringFieldUpdateOperationsInput | string | null
    mediaUrls?: ReportUpdatemediaUrlsInput | string[]
    category?: NullableStringFieldUpdateOperationsInput | string | null
    severity?: NullableIntFieldUpdateOperationsInput | number | null
    status?: EnumReportStatusFieldUpdateOperationsInput | $Enums.ReportStatus
    moderatedAt?: NullableDateTimeFieldUpdateOperationsInput | Date | string | null
    moderationReason?: NullableStringFieldUpdateOperationsInput | string | null
    moderatedById?: NullableStringFieldUpdateOperationsInput | string | null
    potentialDuplicateOfId?: NullableStringFieldUpdateOperationsInput | string | null
    potentialDuplicates?: ReportUncheckedUpdateManyWithoutPotentialDuplicateOfNestedInput
  }

  export type UserUpsertWithoutCoReportedReportsInput = {
    update: XOR<UserUpdateWithoutCoReportedReportsInput, UserUncheckedUpdateWithoutCoReportedReportsInput>
    create: XOR<UserCreateWithoutCoReportedReportsInput, UserUncheckedCreateWithoutCoReportedReportsInput>
    where?: UserWhereInput
  }

  export type UserUpdateToOneWithWhereWithoutCoReportedReportsInput = {
    where?: UserWhereInput
    data: XOR<UserUpdateWithoutCoReportedReportsInput, UserUncheckedUpdateWithoutCoReportedReportsInput>
  }

  export type UserUpdateWithoutCoReportedReportsInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    updatedAt?: DateTimeFieldUpdateOperationsInput | Date | string
    firstName?: StringFieldUpdateOperationsInput | string
    lastName?: StringFieldUpdateOperationsInput | string
    email?: StringFieldUpdateOperationsInput | string
    phoneNumber?: StringFieldUpdateOperationsInput | string
    passwordHash?: StringFieldUpdateOperationsInput | string
    role?: EnumRoleFieldUpdateOperationsInput | $Enums.Role
    status?: EnumUserStatusFieldUpdateOperationsInput | $Enums.UserStatus
    isPhoneVerified?: BoolFieldUpdateOperationsInput | boolean
    pointsBalance?: IntFieldUpdateOperationsInput | number
    totalPointsEarned?: IntFieldUpdateOperationsInput | number
    totalPointsSpent?: IntFieldUpdateOperationsInput | number
    lastActiveAt?: NullableDateTimeFieldUpdateOperationsInput | Date | string | null
    reports?: ReportUpdateManyWithoutReporterNestedInput
    moderatedReports?: ReportUpdateManyWithoutModeratedByNestedInput
    adminNotifications?: AdminNotificationUpdateManyWithoutUserNestedInput
    pointTransactions?: PointTransactionUpdateManyWithoutUserNestedInput
    sessions?: UserSessionUpdateManyWithoutUserNestedInput
  }

  export type UserUncheckedUpdateWithoutCoReportedReportsInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    updatedAt?: DateTimeFieldUpdateOperationsInput | Date | string
    firstName?: StringFieldUpdateOperationsInput | string
    lastName?: StringFieldUpdateOperationsInput | string
    email?: StringFieldUpdateOperationsInput | string
    phoneNumber?: StringFieldUpdateOperationsInput | string
    passwordHash?: StringFieldUpdateOperationsInput | string
    role?: EnumRoleFieldUpdateOperationsInput | $Enums.Role
    status?: EnumUserStatusFieldUpdateOperationsInput | $Enums.UserStatus
    isPhoneVerified?: BoolFieldUpdateOperationsInput | boolean
    pointsBalance?: IntFieldUpdateOperationsInput | number
    totalPointsEarned?: IntFieldUpdateOperationsInput | number
    totalPointsSpent?: IntFieldUpdateOperationsInput | number
    lastActiveAt?: NullableDateTimeFieldUpdateOperationsInput | Date | string | null
    reports?: ReportUncheckedUpdateManyWithoutReporterNestedInput
    moderatedReports?: ReportUncheckedUpdateManyWithoutModeratedByNestedInput
    adminNotifications?: AdminNotificationUncheckedUpdateManyWithoutUserNestedInput
    pointTransactions?: PointTransactionUncheckedUpdateManyWithoutUserNestedInput
    sessions?: UserSessionUncheckedUpdateManyWithoutUserNestedInput
  }

  export type SiteCreateWithoutEventsInput = {
    id?: string
    createdAt?: Date | string
    updatedAt?: Date | string
    latitude: number
    longitude: number
    description?: string | null
    status?: $Enums.SiteStatus
    reports?: ReportCreateNestedManyWithoutSiteInput
  }

  export type SiteUncheckedCreateWithoutEventsInput = {
    id?: string
    createdAt?: Date | string
    updatedAt?: Date | string
    latitude: number
    longitude: number
    description?: string | null
    status?: $Enums.SiteStatus
    reports?: ReportUncheckedCreateNestedManyWithoutSiteInput
  }

  export type SiteCreateOrConnectWithoutEventsInput = {
    where: SiteWhereUniqueInput
    create: XOR<SiteCreateWithoutEventsInput, SiteUncheckedCreateWithoutEventsInput>
  }

  export type SiteUpsertWithoutEventsInput = {
    update: XOR<SiteUpdateWithoutEventsInput, SiteUncheckedUpdateWithoutEventsInput>
    create: XOR<SiteCreateWithoutEventsInput, SiteUncheckedCreateWithoutEventsInput>
    where?: SiteWhereInput
  }

  export type SiteUpdateToOneWithWhereWithoutEventsInput = {
    where?: SiteWhereInput
    data: XOR<SiteUpdateWithoutEventsInput, SiteUncheckedUpdateWithoutEventsInput>
  }

  export type SiteUpdateWithoutEventsInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    updatedAt?: DateTimeFieldUpdateOperationsInput | Date | string
    latitude?: FloatFieldUpdateOperationsInput | number
    longitude?: FloatFieldUpdateOperationsInput | number
    description?: NullableStringFieldUpdateOperationsInput | string | null
    status?: EnumSiteStatusFieldUpdateOperationsInput | $Enums.SiteStatus
    reports?: ReportUpdateManyWithoutSiteNestedInput
  }

  export type SiteUncheckedUpdateWithoutEventsInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    updatedAt?: DateTimeFieldUpdateOperationsInput | Date | string
    latitude?: FloatFieldUpdateOperationsInput | number
    longitude?: FloatFieldUpdateOperationsInput | number
    description?: NullableStringFieldUpdateOperationsInput | string | null
    status?: EnumSiteStatusFieldUpdateOperationsInput | $Enums.SiteStatus
    reports?: ReportUncheckedUpdateManyWithoutSiteNestedInput
  }

  export type ReportCreateManyReporterInput = {
    id?: string
    createdAt?: Date | string
    reportNumber?: string | null
    siteId: string
    description?: string | null
    mediaUrls?: ReportCreatemediaUrlsInput | string[]
    category?: string | null
    severity?: number | null
    status?: $Enums.ReportStatus
    moderatedAt?: Date | string | null
    moderationReason?: string | null
    moderatedById?: string | null
    potentialDuplicateOfId?: string | null
  }

  export type ReportCreateManyModeratedByInput = {
    id?: string
    createdAt?: Date | string
    reportNumber?: string | null
    siteId: string
    reporterId?: string | null
    description?: string | null
    mediaUrls?: ReportCreatemediaUrlsInput | string[]
    category?: string | null
    severity?: number | null
    status?: $Enums.ReportStatus
    moderatedAt?: Date | string | null
    moderationReason?: string | null
    potentialDuplicateOfId?: string | null
  }

  export type AdminNotificationCreateManyUserInput = {
    id?: string
    createdAt?: Date | string
    updatedAt?: Date | string
    title: string
    message: string
    timeLabel: string
    tone: $Enums.AdminNotificationTone
    category: $Enums.AdminNotificationCategory
    isUnread?: boolean
    href?: string | null
  }

  export type PointTransactionCreateManyUserInput = {
    id?: string
    createdAt?: Date | string
    delta: number
    balanceAfter: number
    reasonCode: string
    referenceType?: string | null
    referenceId?: string | null
    metadata?: NullableJsonNullValueInput | InputJsonValue
  }

  export type ReportCoReporterCreateManyUserInput = {
    id?: string
    createdAt?: Date | string
    reportId: string
  }

  export type UserSessionCreateManyUserInput = {
    id?: string
    createdAt?: Date | string
    tokenId: string
    refreshTokenHash: string
    deviceInfo?: string | null
    ipAddress?: string | null
    expiresAt: Date | string
    revokedAt?: Date | string | null
  }

  export type ReportUpdateWithoutReporterInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    reportNumber?: NullableStringFieldUpdateOperationsInput | string | null
    description?: NullableStringFieldUpdateOperationsInput | string | null
    mediaUrls?: ReportUpdatemediaUrlsInput | string[]
    category?: NullableStringFieldUpdateOperationsInput | string | null
    severity?: NullableIntFieldUpdateOperationsInput | number | null
    status?: EnumReportStatusFieldUpdateOperationsInput | $Enums.ReportStatus
    moderatedAt?: NullableDateTimeFieldUpdateOperationsInput | Date | string | null
    moderationReason?: NullableStringFieldUpdateOperationsInput | string | null
    site?: SiteUpdateOneRequiredWithoutReportsNestedInput
    moderatedBy?: UserUpdateOneWithoutModeratedReportsNestedInput
    potentialDuplicateOf?: ReportUpdateOneWithoutPotentialDuplicatesNestedInput
    potentialDuplicates?: ReportUpdateManyWithoutPotentialDuplicateOfNestedInput
    coReporters?: ReportCoReporterUpdateManyWithoutReportNestedInput
  }

  export type ReportUncheckedUpdateWithoutReporterInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    reportNumber?: NullableStringFieldUpdateOperationsInput | string | null
    siteId?: StringFieldUpdateOperationsInput | string
    description?: NullableStringFieldUpdateOperationsInput | string | null
    mediaUrls?: ReportUpdatemediaUrlsInput | string[]
    category?: NullableStringFieldUpdateOperationsInput | string | null
    severity?: NullableIntFieldUpdateOperationsInput | number | null
    status?: EnumReportStatusFieldUpdateOperationsInput | $Enums.ReportStatus
    moderatedAt?: NullableDateTimeFieldUpdateOperationsInput | Date | string | null
    moderationReason?: NullableStringFieldUpdateOperationsInput | string | null
    moderatedById?: NullableStringFieldUpdateOperationsInput | string | null
    potentialDuplicateOfId?: NullableStringFieldUpdateOperationsInput | string | null
    potentialDuplicates?: ReportUncheckedUpdateManyWithoutPotentialDuplicateOfNestedInput
    coReporters?: ReportCoReporterUncheckedUpdateManyWithoutReportNestedInput
  }

  export type ReportUncheckedUpdateManyWithoutReporterInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    reportNumber?: NullableStringFieldUpdateOperationsInput | string | null
    siteId?: StringFieldUpdateOperationsInput | string
    description?: NullableStringFieldUpdateOperationsInput | string | null
    mediaUrls?: ReportUpdatemediaUrlsInput | string[]
    category?: NullableStringFieldUpdateOperationsInput | string | null
    severity?: NullableIntFieldUpdateOperationsInput | number | null
    status?: EnumReportStatusFieldUpdateOperationsInput | $Enums.ReportStatus
    moderatedAt?: NullableDateTimeFieldUpdateOperationsInput | Date | string | null
    moderationReason?: NullableStringFieldUpdateOperationsInput | string | null
    moderatedById?: NullableStringFieldUpdateOperationsInput | string | null
    potentialDuplicateOfId?: NullableStringFieldUpdateOperationsInput | string | null
  }

  export type ReportUpdateWithoutModeratedByInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    reportNumber?: NullableStringFieldUpdateOperationsInput | string | null
    description?: NullableStringFieldUpdateOperationsInput | string | null
    mediaUrls?: ReportUpdatemediaUrlsInput | string[]
    category?: NullableStringFieldUpdateOperationsInput | string | null
    severity?: NullableIntFieldUpdateOperationsInput | number | null
    status?: EnumReportStatusFieldUpdateOperationsInput | $Enums.ReportStatus
    moderatedAt?: NullableDateTimeFieldUpdateOperationsInput | Date | string | null
    moderationReason?: NullableStringFieldUpdateOperationsInput | string | null
    site?: SiteUpdateOneRequiredWithoutReportsNestedInput
    reporter?: UserUpdateOneWithoutReportsNestedInput
    potentialDuplicateOf?: ReportUpdateOneWithoutPotentialDuplicatesNestedInput
    potentialDuplicates?: ReportUpdateManyWithoutPotentialDuplicateOfNestedInput
    coReporters?: ReportCoReporterUpdateManyWithoutReportNestedInput
  }

  export type ReportUncheckedUpdateWithoutModeratedByInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    reportNumber?: NullableStringFieldUpdateOperationsInput | string | null
    siteId?: StringFieldUpdateOperationsInput | string
    reporterId?: NullableStringFieldUpdateOperationsInput | string | null
    description?: NullableStringFieldUpdateOperationsInput | string | null
    mediaUrls?: ReportUpdatemediaUrlsInput | string[]
    category?: NullableStringFieldUpdateOperationsInput | string | null
    severity?: NullableIntFieldUpdateOperationsInput | number | null
    status?: EnumReportStatusFieldUpdateOperationsInput | $Enums.ReportStatus
    moderatedAt?: NullableDateTimeFieldUpdateOperationsInput | Date | string | null
    moderationReason?: NullableStringFieldUpdateOperationsInput | string | null
    potentialDuplicateOfId?: NullableStringFieldUpdateOperationsInput | string | null
    potentialDuplicates?: ReportUncheckedUpdateManyWithoutPotentialDuplicateOfNestedInput
    coReporters?: ReportCoReporterUncheckedUpdateManyWithoutReportNestedInput
  }

  export type ReportUncheckedUpdateManyWithoutModeratedByInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    reportNumber?: NullableStringFieldUpdateOperationsInput | string | null
    siteId?: StringFieldUpdateOperationsInput | string
    reporterId?: NullableStringFieldUpdateOperationsInput | string | null
    description?: NullableStringFieldUpdateOperationsInput | string | null
    mediaUrls?: ReportUpdatemediaUrlsInput | string[]
    category?: NullableStringFieldUpdateOperationsInput | string | null
    severity?: NullableIntFieldUpdateOperationsInput | number | null
    status?: EnumReportStatusFieldUpdateOperationsInput | $Enums.ReportStatus
    moderatedAt?: NullableDateTimeFieldUpdateOperationsInput | Date | string | null
    moderationReason?: NullableStringFieldUpdateOperationsInput | string | null
    potentialDuplicateOfId?: NullableStringFieldUpdateOperationsInput | string | null
  }

  export type AdminNotificationUpdateWithoutUserInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    updatedAt?: DateTimeFieldUpdateOperationsInput | Date | string
    title?: StringFieldUpdateOperationsInput | string
    message?: StringFieldUpdateOperationsInput | string
    timeLabel?: StringFieldUpdateOperationsInput | string
    tone?: EnumAdminNotificationToneFieldUpdateOperationsInput | $Enums.AdminNotificationTone
    category?: EnumAdminNotificationCategoryFieldUpdateOperationsInput | $Enums.AdminNotificationCategory
    isUnread?: BoolFieldUpdateOperationsInput | boolean
    href?: NullableStringFieldUpdateOperationsInput | string | null
  }

  export type AdminNotificationUncheckedUpdateWithoutUserInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    updatedAt?: DateTimeFieldUpdateOperationsInput | Date | string
    title?: StringFieldUpdateOperationsInput | string
    message?: StringFieldUpdateOperationsInput | string
    timeLabel?: StringFieldUpdateOperationsInput | string
    tone?: EnumAdminNotificationToneFieldUpdateOperationsInput | $Enums.AdminNotificationTone
    category?: EnumAdminNotificationCategoryFieldUpdateOperationsInput | $Enums.AdminNotificationCategory
    isUnread?: BoolFieldUpdateOperationsInput | boolean
    href?: NullableStringFieldUpdateOperationsInput | string | null
  }

  export type AdminNotificationUncheckedUpdateManyWithoutUserInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    updatedAt?: DateTimeFieldUpdateOperationsInput | Date | string
    title?: StringFieldUpdateOperationsInput | string
    message?: StringFieldUpdateOperationsInput | string
    timeLabel?: StringFieldUpdateOperationsInput | string
    tone?: EnumAdminNotificationToneFieldUpdateOperationsInput | $Enums.AdminNotificationTone
    category?: EnumAdminNotificationCategoryFieldUpdateOperationsInput | $Enums.AdminNotificationCategory
    isUnread?: BoolFieldUpdateOperationsInput | boolean
    href?: NullableStringFieldUpdateOperationsInput | string | null
  }

  export type PointTransactionUpdateWithoutUserInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    delta?: IntFieldUpdateOperationsInput | number
    balanceAfter?: IntFieldUpdateOperationsInput | number
    reasonCode?: StringFieldUpdateOperationsInput | string
    referenceType?: NullableStringFieldUpdateOperationsInput | string | null
    referenceId?: NullableStringFieldUpdateOperationsInput | string | null
    metadata?: NullableJsonNullValueInput | InputJsonValue
  }

  export type PointTransactionUncheckedUpdateWithoutUserInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    delta?: IntFieldUpdateOperationsInput | number
    balanceAfter?: IntFieldUpdateOperationsInput | number
    reasonCode?: StringFieldUpdateOperationsInput | string
    referenceType?: NullableStringFieldUpdateOperationsInput | string | null
    referenceId?: NullableStringFieldUpdateOperationsInput | string | null
    metadata?: NullableJsonNullValueInput | InputJsonValue
  }

  export type PointTransactionUncheckedUpdateManyWithoutUserInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    delta?: IntFieldUpdateOperationsInput | number
    balanceAfter?: IntFieldUpdateOperationsInput | number
    reasonCode?: StringFieldUpdateOperationsInput | string
    referenceType?: NullableStringFieldUpdateOperationsInput | string | null
    referenceId?: NullableStringFieldUpdateOperationsInput | string | null
    metadata?: NullableJsonNullValueInput | InputJsonValue
  }

  export type ReportCoReporterUpdateWithoutUserInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    report?: ReportUpdateOneRequiredWithoutCoReportersNestedInput
  }

  export type ReportCoReporterUncheckedUpdateWithoutUserInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    reportId?: StringFieldUpdateOperationsInput | string
  }

  export type ReportCoReporterUncheckedUpdateManyWithoutUserInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    reportId?: StringFieldUpdateOperationsInput | string
  }

  export type UserSessionUpdateWithoutUserInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    tokenId?: StringFieldUpdateOperationsInput | string
    refreshTokenHash?: StringFieldUpdateOperationsInput | string
    deviceInfo?: NullableStringFieldUpdateOperationsInput | string | null
    ipAddress?: NullableStringFieldUpdateOperationsInput | string | null
    expiresAt?: DateTimeFieldUpdateOperationsInput | Date | string
    revokedAt?: NullableDateTimeFieldUpdateOperationsInput | Date | string | null
  }

  export type UserSessionUncheckedUpdateWithoutUserInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    tokenId?: StringFieldUpdateOperationsInput | string
    refreshTokenHash?: StringFieldUpdateOperationsInput | string
    deviceInfo?: NullableStringFieldUpdateOperationsInput | string | null
    ipAddress?: NullableStringFieldUpdateOperationsInput | string | null
    expiresAt?: DateTimeFieldUpdateOperationsInput | Date | string
    revokedAt?: NullableDateTimeFieldUpdateOperationsInput | Date | string | null
  }

  export type UserSessionUncheckedUpdateManyWithoutUserInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    tokenId?: StringFieldUpdateOperationsInput | string
    refreshTokenHash?: StringFieldUpdateOperationsInput | string
    deviceInfo?: NullableStringFieldUpdateOperationsInput | string | null
    ipAddress?: NullableStringFieldUpdateOperationsInput | string | null
    expiresAt?: DateTimeFieldUpdateOperationsInput | Date | string
    revokedAt?: NullableDateTimeFieldUpdateOperationsInput | Date | string | null
  }

  export type ReportCreateManySiteInput = {
    id?: string
    createdAt?: Date | string
    reportNumber?: string | null
    reporterId?: string | null
    description?: string | null
    mediaUrls?: ReportCreatemediaUrlsInput | string[]
    category?: string | null
    severity?: number | null
    status?: $Enums.ReportStatus
    moderatedAt?: Date | string | null
    moderationReason?: string | null
    moderatedById?: string | null
    potentialDuplicateOfId?: string | null
  }

  export type CleanupEventCreateManySiteInput = {
    id?: string
    createdAt?: Date | string
    updatedAt?: Date | string
    scheduledAt: Date | string
    completedAt?: Date | string | null
    organizerId?: string | null
    participantCount?: number
  }

  export type ReportUpdateWithoutSiteInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    reportNumber?: NullableStringFieldUpdateOperationsInput | string | null
    description?: NullableStringFieldUpdateOperationsInput | string | null
    mediaUrls?: ReportUpdatemediaUrlsInput | string[]
    category?: NullableStringFieldUpdateOperationsInput | string | null
    severity?: NullableIntFieldUpdateOperationsInput | number | null
    status?: EnumReportStatusFieldUpdateOperationsInput | $Enums.ReportStatus
    moderatedAt?: NullableDateTimeFieldUpdateOperationsInput | Date | string | null
    moderationReason?: NullableStringFieldUpdateOperationsInput | string | null
    reporter?: UserUpdateOneWithoutReportsNestedInput
    moderatedBy?: UserUpdateOneWithoutModeratedReportsNestedInput
    potentialDuplicateOf?: ReportUpdateOneWithoutPotentialDuplicatesNestedInput
    potentialDuplicates?: ReportUpdateManyWithoutPotentialDuplicateOfNestedInput
    coReporters?: ReportCoReporterUpdateManyWithoutReportNestedInput
  }

  export type ReportUncheckedUpdateWithoutSiteInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    reportNumber?: NullableStringFieldUpdateOperationsInput | string | null
    reporterId?: NullableStringFieldUpdateOperationsInput | string | null
    description?: NullableStringFieldUpdateOperationsInput | string | null
    mediaUrls?: ReportUpdatemediaUrlsInput | string[]
    category?: NullableStringFieldUpdateOperationsInput | string | null
    severity?: NullableIntFieldUpdateOperationsInput | number | null
    status?: EnumReportStatusFieldUpdateOperationsInput | $Enums.ReportStatus
    moderatedAt?: NullableDateTimeFieldUpdateOperationsInput | Date | string | null
    moderationReason?: NullableStringFieldUpdateOperationsInput | string | null
    moderatedById?: NullableStringFieldUpdateOperationsInput | string | null
    potentialDuplicateOfId?: NullableStringFieldUpdateOperationsInput | string | null
    potentialDuplicates?: ReportUncheckedUpdateManyWithoutPotentialDuplicateOfNestedInput
    coReporters?: ReportCoReporterUncheckedUpdateManyWithoutReportNestedInput
  }

  export type ReportUncheckedUpdateManyWithoutSiteInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    reportNumber?: NullableStringFieldUpdateOperationsInput | string | null
    reporterId?: NullableStringFieldUpdateOperationsInput | string | null
    description?: NullableStringFieldUpdateOperationsInput | string | null
    mediaUrls?: ReportUpdatemediaUrlsInput | string[]
    category?: NullableStringFieldUpdateOperationsInput | string | null
    severity?: NullableIntFieldUpdateOperationsInput | number | null
    status?: EnumReportStatusFieldUpdateOperationsInput | $Enums.ReportStatus
    moderatedAt?: NullableDateTimeFieldUpdateOperationsInput | Date | string | null
    moderationReason?: NullableStringFieldUpdateOperationsInput | string | null
    moderatedById?: NullableStringFieldUpdateOperationsInput | string | null
    potentialDuplicateOfId?: NullableStringFieldUpdateOperationsInput | string | null
  }

  export type CleanupEventUpdateWithoutSiteInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    updatedAt?: DateTimeFieldUpdateOperationsInput | Date | string
    scheduledAt?: DateTimeFieldUpdateOperationsInput | Date | string
    completedAt?: NullableDateTimeFieldUpdateOperationsInput | Date | string | null
    organizerId?: NullableStringFieldUpdateOperationsInput | string | null
    participantCount?: IntFieldUpdateOperationsInput | number
  }

  export type CleanupEventUncheckedUpdateWithoutSiteInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    updatedAt?: DateTimeFieldUpdateOperationsInput | Date | string
    scheduledAt?: DateTimeFieldUpdateOperationsInput | Date | string
    completedAt?: NullableDateTimeFieldUpdateOperationsInput | Date | string | null
    organizerId?: NullableStringFieldUpdateOperationsInput | string | null
    participantCount?: IntFieldUpdateOperationsInput | number
  }

  export type CleanupEventUncheckedUpdateManyWithoutSiteInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    updatedAt?: DateTimeFieldUpdateOperationsInput | Date | string
    scheduledAt?: DateTimeFieldUpdateOperationsInput | Date | string
    completedAt?: NullableDateTimeFieldUpdateOperationsInput | Date | string | null
    organizerId?: NullableStringFieldUpdateOperationsInput | string | null
    participantCount?: IntFieldUpdateOperationsInput | number
  }

  export type ReportCreateManyPotentialDuplicateOfInput = {
    id?: string
    createdAt?: Date | string
    reportNumber?: string | null
    siteId: string
    reporterId?: string | null
    description?: string | null
    mediaUrls?: ReportCreatemediaUrlsInput | string[]
    category?: string | null
    severity?: number | null
    status?: $Enums.ReportStatus
    moderatedAt?: Date | string | null
    moderationReason?: string | null
    moderatedById?: string | null
  }

  export type ReportCoReporterCreateManyReportInput = {
    id?: string
    createdAt?: Date | string
    userId: string
  }

  export type ReportUpdateWithoutPotentialDuplicateOfInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    reportNumber?: NullableStringFieldUpdateOperationsInput | string | null
    description?: NullableStringFieldUpdateOperationsInput | string | null
    mediaUrls?: ReportUpdatemediaUrlsInput | string[]
    category?: NullableStringFieldUpdateOperationsInput | string | null
    severity?: NullableIntFieldUpdateOperationsInput | number | null
    status?: EnumReportStatusFieldUpdateOperationsInput | $Enums.ReportStatus
    moderatedAt?: NullableDateTimeFieldUpdateOperationsInput | Date | string | null
    moderationReason?: NullableStringFieldUpdateOperationsInput | string | null
    site?: SiteUpdateOneRequiredWithoutReportsNestedInput
    reporter?: UserUpdateOneWithoutReportsNestedInput
    moderatedBy?: UserUpdateOneWithoutModeratedReportsNestedInput
    potentialDuplicates?: ReportUpdateManyWithoutPotentialDuplicateOfNestedInput
    coReporters?: ReportCoReporterUpdateManyWithoutReportNestedInput
  }

  export type ReportUncheckedUpdateWithoutPotentialDuplicateOfInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    reportNumber?: NullableStringFieldUpdateOperationsInput | string | null
    siteId?: StringFieldUpdateOperationsInput | string
    reporterId?: NullableStringFieldUpdateOperationsInput | string | null
    description?: NullableStringFieldUpdateOperationsInput | string | null
    mediaUrls?: ReportUpdatemediaUrlsInput | string[]
    category?: NullableStringFieldUpdateOperationsInput | string | null
    severity?: NullableIntFieldUpdateOperationsInput | number | null
    status?: EnumReportStatusFieldUpdateOperationsInput | $Enums.ReportStatus
    moderatedAt?: NullableDateTimeFieldUpdateOperationsInput | Date | string | null
    moderationReason?: NullableStringFieldUpdateOperationsInput | string | null
    moderatedById?: NullableStringFieldUpdateOperationsInput | string | null
    potentialDuplicates?: ReportUncheckedUpdateManyWithoutPotentialDuplicateOfNestedInput
    coReporters?: ReportCoReporterUncheckedUpdateManyWithoutReportNestedInput
  }

  export type ReportUncheckedUpdateManyWithoutPotentialDuplicateOfInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    reportNumber?: NullableStringFieldUpdateOperationsInput | string | null
    siteId?: StringFieldUpdateOperationsInput | string
    reporterId?: NullableStringFieldUpdateOperationsInput | string | null
    description?: NullableStringFieldUpdateOperationsInput | string | null
    mediaUrls?: ReportUpdatemediaUrlsInput | string[]
    category?: NullableStringFieldUpdateOperationsInput | string | null
    severity?: NullableIntFieldUpdateOperationsInput | number | null
    status?: EnumReportStatusFieldUpdateOperationsInput | $Enums.ReportStatus
    moderatedAt?: NullableDateTimeFieldUpdateOperationsInput | Date | string | null
    moderationReason?: NullableStringFieldUpdateOperationsInput | string | null
    moderatedById?: NullableStringFieldUpdateOperationsInput | string | null
  }

  export type ReportCoReporterUpdateWithoutReportInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    user?: UserUpdateOneRequiredWithoutCoReportedReportsNestedInput
  }

  export type ReportCoReporterUncheckedUpdateWithoutReportInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    userId?: StringFieldUpdateOperationsInput | string
  }

  export type ReportCoReporterUncheckedUpdateManyWithoutReportInput = {
    id?: StringFieldUpdateOperationsInput | string
    createdAt?: DateTimeFieldUpdateOperationsInput | Date | string
    userId?: StringFieldUpdateOperationsInput | string
  }



  /**
   * Batch Payload for updateMany & deleteMany & createMany
   */

  export type BatchPayload = {
    count: number
  }

  /**
   * DMMF
   */
  export const dmmf: runtime.BaseDMMF
}