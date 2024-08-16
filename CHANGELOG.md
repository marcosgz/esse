# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 0.4.0 - 2024-08-16
* Rename lazy_update_document_attributes to update_lazy_attributes
* Rename eager_include_document_attributes to eager_load_lazy_attributes
## 0.3.6 - 2024-08-07
* Esse::LazyDocumentHeader#to_doc return `Esse::LazyDocumentHeader::Document` instance to properly separate context metadata from document source
* Add `.collection_class` method to the `Esse::Repository` class to let external plugins and extensions to access it instead of read @collection_proc variable

## 0.3.5 - 2024-08-02
* Add `update_by_query` action to transport and index APIs
* Reset index using `_reindex` api instead of the traditional collection `import` method
* Add --settings option to the CLI
* Lazy document attributes support

## 0.3.2 - 2024-07-12
* fix bulk indexing routing issue
* add `attributes:` to the `Esse::Repository.each_serialized_batch` to preload `lazy_document_attributes`
* Stop stringifying the `lazy_document_attributes` attribute name
* The `Esse::Repository.update_documents_attribute` was not working when calling with a single hash as document

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
