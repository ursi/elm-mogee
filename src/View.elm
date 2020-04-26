module View exposing (view)

import Components.Components as Components
import Components.Keys as Keys
import Components.Menu as Menu
import Components.Transform as Transform exposing (Transform)
import Html exposing (Html)
import Html.Attributes exposing (height, style, width)
import Messages exposing (Msg)
import Model exposing (GameState(..), Model)
import Slides.View as Slides
import View.Color as Color
import View.Common as Common
import View.Components
import View.Font as Font exposing (Text)
import View.Lives as Lives
import View.Menu as Menu
import WebGL exposing (Entity)
import WebGL.Texture exposing (Texture)


view : Model -> Html Msg
view model =
    let
        ( w, h ) =
            model.size

        size =
            max 1 (min w h // 64 - model.padding) * 64
    in
    WebGL.toHtmlWith
        [ WebGL.depth 1
        , WebGL.stencil 0
        , WebGL.clearColor (22 / 255) (17 / 255) (22 / 255) 0
        ]
        [ width size
        , height size
        , style "display" "block"
        , style "position" "absolute"
        , style "top" "50%"
        , style "left" "50%"
        , style "margin-top" (String.fromInt (-size // 2) ++ "px")
        , style "margin-left" (String.fromInt (-size // 2) ++ "px")
        , style "image-rendering" "optimizeSpeed"
        , style "image-rendering" "-moz-crisp-edges"
        , style "image-rendering" "-webkit-optimize-contrast"
        , style "image-rendering" "crisp-edges"
        , style "image-rendering" "pixelated"
        , style "-ms-interpolation-mode" "nearest-neighbor"
        ]
        (Maybe.map2 (render model)
            model.font
            model.sprite
            |> Maybe.withDefault []
        )


toMinimap : Transform -> Transform
toMinimap { x, y } =
    { x = floor (x / 64) |> toFloat
    , y = floor (y / 64) |> toFloat
    , width = 1
    , height = 1
    }


render : Model -> Texture -> Texture -> List Entity
render model font sprite =
    case model.state of
        Initial menu ->
            if menu.section == Menu.SlidesSection then
                Slides.render sprite font model.slides

            else
                Menu.render model.sound font sprite menu

        Paused menu ->
            Menu.render model.sound font sprite menu
                ++ renderGame model sprite

        Dead ->
            Font.render Color.white continueText font ( 12, 40, 0 )
                :: renderGame model sprite

        Playing ->
            renderGame model sprite


renderGame : Model -> Texture -> List Entity
renderGame { components, systems, score, keys, lives } sprite =
    let
        mogeeTransform =
            Components.mogeeOffset components

        {- camera offset must be an integer, because pixels -}
        cameraOffset =
            ( toFloat (round mogeeTransform.x) - 28
            , toFloat (round mogeeTransform.y) - 27
            )

        mogeeMinimap =
            toMinimap mogeeTransform

        allScr =
            Components.foldl2
                (\_ _ position positions -> toMinimap position :: positions)
                []
                components.screens
                components.transforms

        maxX =
            List.maximum (List.map .x allScr) |> Maybe.withDefault 0

        minY =
            List.minimum (List.map .y allScr) |> Maybe.withDefault 0

        dot transform =
            Common.rectangle
                False
                (Transform.offsetBy ( maxX - 62, minY - 1 ) transform)
                0
                (if transform == mogeeMinimap then
                    Color.yellow

                 else
                    Color.gray
                )
    in
    Lives.renderLives sprite ( 1, 1, 0 ) lives
        ++ Lives.renderScore sprite ( 32, 1, 0 ) (systems.currentScore + score)
        ++ List.map dot allScr
        ++ View.Components.render sprite (Keys.directions keys).x cameraOffset components []


continueText : Text
continueText =
    Font.text "press enter\nto continue"
