module Kit.Ast.Definitions.TraitImplementation where

import Control.Monad
import Kit.Ast.Definitions.Base
import Kit.Ast.Definitions.FunctionDefinition
import Kit.Ast.Definitions.TraitDefinition
import Kit.Ast.Metadata
import Kit.Ast.Modifier
import Kit.Ast.ModulePath
import Kit.Ast.TypePath
import Kit.Ast.TypeSpec
import Kit.Parser.Span
import Kit.Str

data TraitImplementation a b = TraitImplementation {
  implName :: TypePath,
  implTrait :: b,
  implFor :: b,
  implParams :: [TypeParam],
  implAssocTypes :: [b],
  implMethods :: [FunctionDefinition a b],
  implDoc :: Maybe Str,
  implPos :: Span
} deriving (Eq, Show)

associatedTypes traitDef impl =
  [ (traitSubPath traitDef $ paramName p, t)
  | (p, t) <- zip (traitAssocParams traitDef) (implAssocTypes impl)
  ]

newTraitImplementation = TraitImplementation
  { implName       = undefined
  , implTrait      = undefined
  , implFor        = undefined
  , implParams     = []
  , implAssocTypes = []
  , implMethods    = []
  , implDoc        = Nothing
  , implPos        = NoPos
  }

convertTraitImplementation
  :: (Monad m)
  => Converter m a b c d
  -> TraitImplementation a b
  -> m (TraitImplementation c d)
convertTraitImplementation converter@(Converter { exprConverter = exprConverter, typeConverter = typeConverter }) i
  = do
    trait      <- typeConverter (implPos i) (implTrait i)
    for        <- typeConverter (implPos i) (implFor i)
    assocTypes <- forM (implAssocTypes i) $ typeConverter (implPos i)
    methods    <- forM (implMethods i)
                       (\f -> convertFunctionDefinition (\p -> converter) f)
    return $ (newTraitImplementation) { implName       = implName i
                                      , implTrait      = trait
                                      , implFor        = for
                                      , implParams     = implParams i
                                      , implAssocTypes = assocTypes
                                      , implMethods    = methods
                                      , implDoc        = implDoc i
                                      , implPos        = implPos i
                                      }

vThisArgName :: Str
vThisArgName = "__vthis"
