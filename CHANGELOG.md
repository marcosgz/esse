# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 0.3.0 - 2024-07-10
* Extend bulk indexing API to support `update`.
* Last attempt of bulk, index each document individually if the bulk fails.
* Include lazy_document_attributes in the index repository
* Tune index settings for better performance during index reset

## 0.2.4 - 2023-11-15
* Add `limit` method to the `Esse::Search::Query` class
* Add `offset` method to the `Esse::Search::Query` class
* Add `limit_value` method to the `Esse::Search::Query` class
* Add `offset_value` method to the `Esse::Search::Query` class
* Expose `cluster` method to the `Esse` module as a shortcut to `Esse.config.cluster`
* Add `deep_dup` method to the `Esse::HashUtils` module
* Move pagination and mutation related methods to a new mixin `Esse::Search::Query::DSL`
