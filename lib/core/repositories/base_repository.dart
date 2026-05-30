// All data source access goes through a repository interface.
// No widget, provider, or service should import dart:io, database packages,
// or HTTP packages directly — call a repository method instead.
abstract interface class Repository {}
