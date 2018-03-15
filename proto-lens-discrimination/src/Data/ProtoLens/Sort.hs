-- | This module implements discriminators of protobufs generically.

{-# LANGUAGE GADTs #-}
{-# LANGUAGE Rank2Types #-}
{-# LANGUAGE ScopedTypeVariables #-}
module Data.ProtoLens.Sort
    (
    -- * Comparing Protobuf Messages
      compareMessage

    -- * 'Sort's for Messages
    , sortingMessage
    , sortingFields
    , sortingField

    -- * 'Sort' for individual field values
    , sortingFieldValue
    ) where

import Data.Functor.Contravariant
    ( (>$<)
    )
import Data.Discrimination
    ( Grouping(grouping)
    , Sort
    , Sorting(sorting)
    , Sorting1(sorting1)
    , sortingCompare
    )
import Data.Discrimination.IEEE754 (sortingFloat, sortingDouble)

import Data.ProtoLens.Message
    ( Message(fieldsByTag)
    , FieldDescriptor
    , FieldTypeDescriptor(..)
    , ScalarField(..)
    )
import Data.ProtoLens.Discrimination
    ( discFields
    , discField
    , discText
    , discByteString
    )
import Data.ProtoLens.Group (groupingMessage)

-- Used to adapt 'sortingCompare' to protobuf types without adding an orphan
-- instance for Sorting.
newtype MessageSorting a = MessageSorting { getMessageSorting :: a }
instance Message a => Grouping (MessageSorting a) where
    grouping = getMessageSorting >$< groupingMessage
instance Message a => Sorting (MessageSorting a) where
    sorting = getMessageSorting >$< sortingMessage

-- | Compare protobuf message values according to their Message instance.
compareMessage :: Message a => a -> a -> Ordering
compareMessage x y = sortingCompare (MessageSorting x) (MessageSorting y)

-- | Sort protobuf message values according to their Message instance.
sortingMessage :: Message a => Sort a
sortingMessage = sortingFields fieldsByTag

-- | Sort values according to a Foldable of field descriptors.
sortingFields :: Foldable t => t (FieldDescriptor a) -> Sort a
sortingFields = discFields sortingFieldValue sorting1 sorting1

-- | Sort values on a single field.
--
-- Note that if you don't need the ability to sort on different fields
-- dynamically, you can probably 'contramap' a specific Sort instead.
-- For example, a Sort by a message or group field:
-- >>> view mySubmessage >$< sortingMessage
--
-- Or to sort by an integer field:
-- >>> sortWith (view myIntField) protos
sortingField :: FieldDescriptor a -> Sort a
sortingField = discField sortingFieldValue sorting1 sorting1

-- | Sort values of a single field of a protobuf according to their 'Message'
-- or 'Sorting' instances.
sortingFieldValue :: FieldTypeDescriptor v -> Sort v
sortingFieldValue ty = case ty of
    MessageField _ -> sortingMessage
    ScalarField  f -> case f of
        EnumField     -> fromEnum >$< sorting
        Int32Field    -> sorting
        Int64Field    -> sorting
        UInt32Field   -> sorting
        UInt64Field   -> sorting
        SInt32Field   -> sorting
        SInt64Field   -> sorting
        Fixed32Field  -> sorting
        Fixed64Field  -> sorting
        SFixed32Field -> sorting
        SFixed64Field -> sorting
        FloatField    -> sortingFloat
        DoubleField   -> sortingDouble
        BoolField     -> sorting
        StringField   -> discText sorting
        BytesField    -> discByteString sorting sorting
