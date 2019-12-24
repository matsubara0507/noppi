module Main exposing (main)

import Browser
import Browser.Navigation as Nav
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Event
import Http
import Json.Decode as Json
import Random exposing (Generator)
import Random.List as Randome
import Url exposing (Url)
import Url.Parser as Url exposing ((<?>))
import Url.Parser.Query as UrlQuery


main : Program () Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = \_ -> Sub.none
        , onUrlRequest = LinkClicked
        , onUrlChange = UrlChanged
        }


type alias Model =
    { questions : List Question
    , key : Nav.Key
    }


type alias Question =
    { enable : Bool
    , url : String
    , image : String
    }


decodeQuestion : Json.Decoder Question
decodeQuestion =
    Json.map3 Question
        (Json.field "enable" Json.bool)
        (Json.field "url" Json.string)
        (Json.field "image" Json.string)


type Msg
    = Fetch (List Question)
    | FetchErr Http.Error
    | Shuffle (List Question)
    | ClickNext
    | LinkClicked Browser.UrlRequest
    | UrlChanged Url


init : () -> Url -> Nav.Key -> ( Model, Cmd Msg )
init _ url key =
    initModel url (Model [] key)


initModel : Url -> Model -> ( Model, Cmd Msg )
initModel url model =
    { url | path = "" }
        |> Url.parse (Url.top <?> UrlQuery.string "questions")
        |> Maybe.withDefault Nothing
        |> Maybe.map fetch
        |> Maybe.withDefault Cmd.none
        |> (\cmd -> ( model, cmd ))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model.questions ) of
        ( Fetch questions, _ ) ->
            ( model
            , List.filter .enable questions
                |> Randome.shuffle
                |> Random.generate Shuffle
            )

        ( Shuffle questions, _ ) ->
            ( { model | questions = questions }, Cmd.none )

        ( ClickNext, _ :: questions ) ->
            ( { model | questions = questions }, Cmd.none )

        ( LinkClicked (Browser.Internal url), _ ) ->
            ( model, Nav.pushUrl model.key (Url.toString url) )

        ( LinkClicked (Browser.External href), _ ) ->
            ( model, Nav.load href )

        ( UrlChanged url, _ ) ->
            initModel url model

        _ ->
            ( model, Cmd.none )


view : Model -> Browser.Document Msg
view model =
    { title = "NOPPI GP", body = [ viewBody model ] }


viewBody : Model -> Html Msg
viewBody model =
    let
        question =
            List.head model.questions
                |> Maybe.map viewQuestion
                |> Maybe.withDefault [ Html.text "Questions is empty..." ]
    in
    Html.div [ Attr.class "m-3", Attr.style "text-align" "center" ]
        (viewNext :: question)


viewQuestion : Question -> List (Html msg)
viewQuestion q =
    [ Html.a [ Attr.href q.url ]
        [ Html.img [ Attr.src q.image, Attr.style "width" "60em" ] [] ]
    ]


viewNext : Html Msg
viewNext =
    Html.div [ Attr.class "f3 m-2", Event.onClick ClickNext ]
        [ Html.button
            [ Attr.class "btn btn-large btn-outline-blue mr-2", Attr.type_ "button" ]
            [ Html.text "NEXT" ]
        ]


fetch : String -> Cmd Msg
fetch url =
    Http.get
        { url = url
        , expect = Http.expectJson fromResult (Json.list decodeQuestion)
        }


fromResult : Result Http.Error (List Question) -> Msg
fromResult res =
    case res of
        Ok questions ->
            Fetch questions

        Err err ->
            FetchErr err
