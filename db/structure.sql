SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

-- *not* creating schema, since initdb creates it


--
-- Name: guard_shop_currency_receipt(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.guard_shop_currency_receipt() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    IF OLD.reason IN ('shop.purchase', 'shop.sale') THEN
      RAISE EXCEPTION 'Shop purchase/sale receipts are append-only'
        USING ERRCODE = '23514', CONSTRAINT = 'currency_transactions_shop_append_only';
    END IF;
  ELSIF TG_OP = 'UPDATE' THEN
    IF OLD.reason IN ('shop.purchase', 'shop.sale') OR NEW.reason IN ('shop.purchase', 'shop.sale') THEN
      RAISE EXCEPTION 'Shop purchase/sale receipts are append-only'
        USING ERRCODE = '23514', CONSTRAINT = 'currency_transactions_shop_append_only';
    END IF;
  ELSIF NEW.reason IN ('shop.purchase', 'shop.sale') THEN
    IF NOT EXISTS (
      SELECT 1
      FROM world_action_offers offers
      JOIN characters owners ON owners.id = offers.character_id
      JOIN currency_wallets wallets ON wallets.id = NEW.currency_wallet_id
      WHERE offers.id = NEW.shop_offer_id
        AND owners.user_id = wallets.user_id
        AND offers.action_type = CASE NEW.reason WHEN 'shop.purchase' THEN 'shop_buy' ELSE 'shop_sell' END
        AND offers.metadata ->> 'shop_account_id' = NEW.shop_account_id::text
    ) THEN
      RAISE EXCEPTION 'Shop receipt references do not match its wallet, action and account'
        USING ERRCODE = '23514', CONSTRAINT = 'currency_transactions_shop_reference_match';
    END IF;
  END IF;
  RETURN NULL;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: airship_journeys; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.airship_journeys (
    id bigint NOT NULL,
    arrives_at timestamp(6) without time zone NOT NULL,
    boarded_at timestamp(6) without time zone NOT NULL,
    boarding_offer_id bigint NOT NULL,
    character_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    departs_at timestamp(6) without time zone NOT NULL,
    destination_x integer NOT NULL,
    destination_y integer NOT NULL,
    destination_zone_id bigint NOT NULL,
    disembarked_at timestamp(6) without time zone,
    error_message character varying,
    fare_nv numeric(12,2) NOT NULL,
    last_position_x integer NOT NULL,
    last_position_y integer NOT NULL,
    last_position_zone_id bigint NOT NULL,
    route_key character varying NOT NULL,
    route_label character varying NOT NULL,
    source_x integer NOT NULL,
    source_y integer NOT NULL,
    source_zone_id bigint NOT NULL,
    status integer DEFAULT 0 NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    waypoints jsonb DEFAULT '[]'::jsonb NOT NULL,
    CONSTRAINT airship_ordered_deadlines CHECK (((boarded_at <= departs_at) AND (departs_at < arrives_at))),
    CONSTRAINT airship_positive_fare CHECK ((fare_nv > (0)::numeric))
);


--
-- Name: airship_journeys_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.airship_journeys_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: airship_journeys_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.airship_journeys_id_seq OWNED BY public.airship_journeys.id;


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: arena_applications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.arena_applications (
    id bigint NOT NULL,
    applicant_id bigint,
    arena_match_id bigint,
    arena_room_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    enemy_count integer,
    enemy_level_max integer,
    enemy_level_min integer,
    expires_at timestamp(6) without time zone,
    fight_kind integer DEFAULT 0 NOT NULL,
    fight_type integer DEFAULT 0 NOT NULL,
    matched_at timestamp(6) without time zone,
    matched_with_id bigint,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    npc_template_id bigint,
    starts_at timestamp(6) without time zone,
    status integer DEFAULT 0 NOT NULL,
    team_count integer DEFAULT 1,
    team_level_max integer,
    team_level_min integer,
    timeout_seconds integer DEFAULT 180 NOT NULL,
    trauma_percent integer DEFAULT 30 NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    wait_minutes integer DEFAULT 10
);


--
-- Name: arena_applications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.arena_applications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: arena_applications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.arena_applications_id_seq OWNED BY public.arena_applications.id;


--
-- Name: arena_matches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.arena_matches (
    id bigint NOT NULL,
    arena_room_id bigint,
    bracket_position character varying,
    created_at timestamp(6) without time zone NOT NULL,
    current_turn_number integer DEFAULT 0,
    current_turn_started_at timestamp(6) without time zone,
    current_turn_team character varying,
    ended_at timestamp(6) without time zone,
    match_type integer DEFAULT 0 NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    started_at timestamp(6) without time zone,
    status integer DEFAULT 0 NOT NULL,
    timed_out boolean DEFAULT false,
    trauma_percent integer DEFAULT 30,
    turn_timeout_seconds integer DEFAULT 300,
    updated_at timestamp(6) without time zone NOT NULL,
    winning_team character varying,
    zone_id bigint
);


--
-- Name: arena_matches_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.arena_matches_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: arena_matches_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.arena_matches_id_seq OWNED BY public.arena_matches.id;


--
-- Name: arena_participations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.arena_participations (
    id bigint NOT NULL,
    arena_match_id bigint NOT NULL,
    character_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    ended_at timestamp(6) without time zone,
    joined_at timestamp(6) without time zone NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    npc_template_id bigint,
    result integer DEFAULT 0 NOT NULL,
    team character varying NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    user_id bigint
);


--
-- Name: arena_participations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.arena_participations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: arena_participations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.arena_participations_id_seq OWNED BY public.arena_participations.id;


--
-- Name: arena_rooms; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.arena_rooms (
    id bigint NOT NULL,
    active boolean DEFAULT true NOT NULL,
    alignment_restriction character varying,
    created_at timestamp(6) without time zone NOT NULL,
    level_max integer DEFAULT 100 NOT NULL,
    level_min integer DEFAULT 0 NOT NULL,
    max_concurrent_matches integer DEFAULT 10 NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    name character varying NOT NULL,
    room_type integer DEFAULT 1 NOT NULL,
    slug character varying NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    zone_id bigint
);


--
-- Name: arena_rooms_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.arena_rooms_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: arena_rooms_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.arena_rooms_id_seq OWNED BY public.arena_rooms.id;


--
-- Name: character_injuries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.character_injuries (
    id bigint NOT NULL,
    character_id bigint NOT NULL,
    arena_match_id bigint,
    severity character varying NOT NULL,
    name character varying NOT NULL,
    stat_penalty_percent integer DEFAULT 0 NOT NULL,
    expires_at timestamp(6) without time zone NOT NULL,
    healed_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT injury_penalty CHECK (((stat_penalty_percent >= 0) AND (stat_penalty_percent <= 90))),
    CONSTRAINT injury_severity CHECK (((severity)::text = ANY ((ARRAY['light'::character varying, 'medium'::character varying, 'heavy'::character varying, 'combat'::character varying])::text[])))
);


--
-- Name: character_injuries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.character_injuries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: character_injuries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.character_injuries_id_seq OWNED BY public.character_injuries.id;


--
-- Name: character_licenses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.character_licenses (
    id bigint NOT NULL,
    character_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    expires_at timestamp(6) without time zone NOT NULL,
    item_template_id bigint NOT NULL,
    kind character varying NOT NULL,
    name character varying NOT NULL,
    starts_at timestamp(6) without time zone NOT NULL,
    tier integer NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    world_action_offer_id bigint NOT NULL,
    CONSTRAINT character_licenses_known_kind CHECK (((kind)::text = ANY (ARRAY[('trading'::character varying)::text, ('doctor'::character varying)::text]))),
    CONSTRAINT character_licenses_known_tier CHECK (((tier >= 1) AND (tier <= 3))),
    CONSTRAINT character_licenses_positive_interval CHECK ((expires_at > starts_at))
);


--
-- Name: character_licenses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.character_licenses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: character_licenses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.character_licenses_id_seq OWNED BY public.character_licenses.id;


--
-- Name: character_positions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.character_positions (
    id bigint NOT NULL,
    character_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    last_action_at timestamp(6) without time zone,
    last_turn_number integer DEFAULT 0 NOT NULL,
    state integer DEFAULT 0 NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    x integer NOT NULL,
    y integer NOT NULL,
    zone_id bigint NOT NULL
);


--
-- Name: character_positions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.character_positions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: character_positions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.character_positions_id_seq OWNED BY public.character_positions.id;


--
-- Name: characters; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.characters (
    id bigint NOT NULL,
    alignment character varying DEFAULT 'none'::character varying NOT NULL,
    allocated_stats jsonb DEFAULT '{}'::jsonb NOT NULL,
    combat_skill_points integer DEFAULT 10 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    current_hp integer DEFAULT 5 NOT NULL,
    current_mp integer DEFAULT 7 NOT NULL,
    experience bigint DEFAULT 0 NOT NULL,
    fatigue_percent integer DEFAULT 0 NOT NULL,
    fatigue_updated_at timestamp(6) without time zone,
    hp_regen_interval integer DEFAULT 300 NOT NULL,
    in_combat boolean DEFAULT false NOT NULL,
    last_combat_at timestamp(6) without time zone,
    last_level_up_at timestamp(6) without time zone,
    last_regen_tick_at timestamp(6) without time zone,
    level integer DEFAULT 0 NOT NULL,
    max_hp integer DEFAULT 5 NOT NULL,
    max_mp integer DEFAULT 7 NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    mp_regen_interval integer DEFAULT 600 NOT NULL,
    name character varying NOT NULL,
    passive_skills jsonb DEFAULT '{}'::jsonb NOT NULL,
    peace_skill_points integer DEFAULT 2 NOT NULL,
    perk_points integer DEFAULT 1 NOT NULL,
    perks jsonb DEFAULT '{}'::jsonb NOT NULL,
    stat_points_available integer DEFAULT 15 NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    user_id bigint NOT NULL
);


--
-- Name: characters_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.characters_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: characters_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.characters_id_seq OWNED BY public.characters.id;


--
-- Name: chat_channel_memberships; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.chat_channel_memberships (
    id bigint NOT NULL,
    chat_channel_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    user_id bigint NOT NULL
);


--
-- Name: chat_channel_memberships_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.chat_channel_memberships_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: chat_channel_memberships_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.chat_channel_memberships_id_seq OWNED BY public.chat_channel_memberships.id;


--
-- Name: chat_channels; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.chat_channels (
    id bigint NOT NULL,
    channel_type integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    creator_id bigint,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    name character varying NOT NULL,
    slug character varying NOT NULL,
    system_owned boolean DEFAULT false NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: chat_channels_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.chat_channels_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: chat_channels_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.chat_channels_id_seq OWNED BY public.chat_channels.id;


--
-- Name: chat_messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.chat_messages (
    id bigint NOT NULL,
    body text NOT NULL,
    chat_channel_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    sender_id bigint NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    visibility integer DEFAULT 0 NOT NULL
);


--
-- Name: chat_messages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.chat_messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: chat_messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.chat_messages_id_seq OWNED BY public.chat_messages.id;


--
-- Name: city_hotspots; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.city_hotspots (
    id bigint NOT NULL,
    action_params jsonb DEFAULT '{}'::jsonb,
    action_type character varying DEFAULT 'open_feature'::character varying NOT NULL,
    active boolean DEFAULT true,
    created_at timestamp(6) without time zone NOT NULL,
    destination_zone_id bigint,
    height integer,
    hotspot_type character varying DEFAULT 'building'::character varying NOT NULL,
    image_hover character varying,
    image_normal character varying,
    key character varying NOT NULL,
    name character varying NOT NULL,
    position_x integer NOT NULL,
    position_y integer NOT NULL,
    required_level integer DEFAULT 0,
    updated_at timestamp(6) without time zone NOT NULL,
    width integer,
    z_index integer DEFAULT 0,
    zone_id bigint NOT NULL
);


--
-- Name: city_hotspots_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.city_hotspots_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: city_hotspots_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.city_hotspots_id_seq OWNED BY public.city_hotspots.id;


--
-- Name: combat_log_entries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.combat_log_entries (
    id bigint NOT NULL,
    action_key character varying,
    actor_id bigint,
    actor_team character varying,
    actor_type character varying,
    arena_match_id bigint NOT NULL,
    body_part character varying,
    created_at timestamp(6) without time zone NOT NULL,
    damage_amount integer DEFAULT 0 NOT NULL,
    log_type character varying DEFAULT 'action'::character varying NOT NULL,
    message text NOT NULL,
    occurred_at timestamp(6) without time zone,
    outcome character varying,
    payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    round_number integer DEFAULT 1 NOT NULL,
    sequence integer DEFAULT 1 NOT NULL,
    tags character varying[] DEFAULT '{}'::character varying[],
    target_id bigint,
    target_team character varying,
    target_type character varying,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: combat_log_entries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.combat_log_entries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: combat_log_entries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.combat_log_entries_id_seq OWNED BY public.combat_log_entries.id;


--
-- Name: currency_transactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.currency_transactions (
    id bigint NOT NULL,
    amount numeric(12,2) NOT NULL,
    balance_after numeric(12,2) DEFAULT 0.0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    currency_wallet_id bigint NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    reason character varying NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    shop_offer_id bigint GENERATED ALWAYS AS (
CASE
    WHEN ((reason)::text = ANY (ARRAY[('shop.purchase'::character varying)::text, ('shop.sale'::character varying)::text])) THEN ((metadata ->> 'shop_offer_id'::text))::bigint
    ELSE NULL::bigint
END) STORED,
    shop_account_id bigint GENERATED ALWAYS AS (
CASE
    WHEN ((reason)::text = ANY (ARRAY[('shop.purchase'::character varying)::text, ('shop.sale'::character varying)::text])) THEN ((metadata ->> 'shop_account_id'::text))::bigint
    ELSE NULL::bigint
END) STORED,
    CONSTRAINT currency_transactions_bounded_balance CHECK (((balance_after >= (0)::numeric) AND (balance_after < ('10000000000'::bigint)::numeric))),
    CONSTRAINT currency_transactions_finite_nonzero_amount CHECK (((amount > ('-10000000000'::bigint)::numeric) AND (amount < ('10000000000'::bigint)::numeric) AND (amount <> (0)::numeric))),
    CONSTRAINT currency_transactions_shop_amount_direction CHECK (((((reason)::text <> 'shop.purchase'::text) OR (amount < (0)::numeric)) AND (((reason)::text <> 'shop.sale'::text) OR (amount > (0)::numeric)))),
    CONSTRAINT currency_transactions_shop_references CHECK ((((reason)::text <> ALL (ARRAY[('shop.purchase'::character varying)::text, ('shop.sale'::character varying)::text])) OR ((jsonb_typeof(metadata) = 'object'::text) AND (jsonb_typeof((metadata -> 'shop_offer_id'::text)) = 'number'::text) AND (jsonb_typeof((metadata -> 'shop_account_id'::text)) = 'number'::text) AND (shop_offer_id IS NOT NULL) AND (shop_offer_id > 0) AND (shop_account_id IS NOT NULL) AND (shop_account_id > 0))))
);


--
-- Name: currency_transactions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.currency_transactions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: currency_transactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.currency_transactions_id_seq OWNED BY public.currency_transactions.id;


--
-- Name: currency_wallets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.currency_wallets (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    nv_balance numeric(12,2) DEFAULT 0.0 NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    user_id bigint NOT NULL,
    CONSTRAINT currency_wallets_bounded_balance CHECK (((nv_balance >= (0)::numeric) AND (nv_balance < ('10000000000'::bigint)::numeric)))
);


--
-- Name: currency_wallets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.currency_wallets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: currency_wallets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.currency_wallets_id_seq OWNED BY public.currency_wallets.id;


--
-- Name: game_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.game_events (
    id bigint NOT NULL,
    body text NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    event_key character varying NOT NULL,
    event_type character varying NOT NULL,
    occurred_at timestamp(6) without time zone NOT NULL,
    payload jsonb DEFAULT '{}'::jsonb NOT NULL,
    recipient_id bigint,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT game_events_audience_check CHECK (((((event_type)::text = 'world_announcement'::text) AND (recipient_id IS NULL)) OR (((event_type)::text <> 'world_announcement'::text) AND (recipient_id IS NOT NULL)))),
    CONSTRAINT game_events_payload_object_check CHECK ((jsonb_typeof(payload) = 'object'::text)),
    CONSTRAINT game_events_type_check CHECK (((event_type)::text = ANY (ARRAY[('fight_finished'::character varying)::text, ('item_found'::character varying)::text, ('money_found'::character varying)::text, ('system_information'::character varying)::text, ('world_announcement'::character varying)::text])))
);


--
-- Name: game_events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.game_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: game_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.game_events_id_seq OWNED BY public.game_events.id;


--
-- Name: ignore_list_entries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ignore_list_entries (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    ignored_user_id bigint NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    user_id bigint NOT NULL
);


--
-- Name: ignore_list_entries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ignore_list_entries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ignore_list_entries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ignore_list_entries_id_seq OWNED BY public.ignore_list_entries.id;


--
-- Name: injury_treatments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.injury_treatments (
    id bigint NOT NULL,
    character_injury_id bigint NOT NULL,
    healer_id bigint NOT NULL,
    inventory_item_id bigint,
    price integer DEFAULT 0 NOT NULL,
    status character varying DEFAULT 'pending'::character varying NOT NULL,
    expires_at timestamp(6) without time zone NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT treatment_price CHECK (((price >= 0) AND (price <= 7000))),
    CONSTRAINT treatment_status CHECK (((status)::text = ANY ((ARRAY['pending'::character varying, 'completed'::character varying, 'declined'::character varying])::text[])))
);


--
-- Name: injury_treatments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.injury_treatments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: injury_treatments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.injury_treatments_id_seq OWNED BY public.injury_treatments.id;


--
-- Name: inventories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.inventories (
    id bigint NOT NULL,
    character_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    currency_storage jsonb DEFAULT '{}'::jsonb NOT NULL,
    current_weight integer DEFAULT 0 NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    slot_capacity integer DEFAULT 30 NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    weight_capacity integer DEFAULT 100 NOT NULL
);


--
-- Name: inventories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.inventories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: inventories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.inventories_id_seq OWNED BY public.inventories.id;


--
-- Name: inventory_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.inventory_items (
    id bigint NOT NULL,
    bound boolean DEFAULT false NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    enhancement_level integer DEFAULT 0 NOT NULL,
    equipment_slot character varying,
    equipped boolean DEFAULT false NOT NULL,
    inventory_id bigint NOT NULL,
    item_template_id bigint NOT NULL,
    last_enhanced_at timestamp(6) without time zone,
    properties jsonb DEFAULT '{}'::jsonb NOT NULL,
    quantity integer DEFAULT 1 NOT NULL,
    slot_index integer,
    slot_kind character varying,
    updated_at timestamp(6) without time zone NOT NULL,
    weight integer DEFAULT 0 NOT NULL
);


--
-- Name: inventory_items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.inventory_items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: inventory_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.inventory_items_id_seq OWNED BY public.inventory_items.id;


--
-- Name: item_templates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.item_templates (
    id bigint NOT NULL,
    base_price integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    durability_max integer DEFAULT 0 NOT NULL,
    enhancement_rules jsonb DEFAULT '{}'::jsonb NOT NULL,
    item_type character varying DEFAULT 'equipment'::character varying,
    key character varying,
    name character varying NOT NULL,
    requirements jsonb DEFAULT '{}'::jsonb NOT NULL,
    slot character varying NOT NULL,
    stack_limit integer DEFAULT 99 NOT NULL,
    stat_modifiers jsonb DEFAULT '{}'::jsonb NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    weight integer DEFAULT 1 NOT NULL
);


--
-- Name: item_templates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.item_templates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: item_templates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.item_templates_id_seq OWNED BY public.item_templates.id;


--
-- Name: management_audit_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.management_audit_events (
    id bigint NOT NULL,
    action character varying NOT NULL,
    actor_id bigint NOT NULL,
    change_set jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    record_id bigint NOT NULL,
    record_label character varying NOT NULL,
    record_type character varying NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT management_audit_events_action_check CHECK (((action)::text = ANY (ARRAY[('create'::character varying)::text, ('update'::character varying)::text, ('destroy'::character varying)::text])))
);


--
-- Name: management_audit_events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.management_audit_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: management_audit_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.management_audit_events_id_seq OWNED BY public.management_audit_events.id;


--
-- Name: map_tile_templates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.map_tile_templates (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    passable boolean DEFAULT true NOT NULL,
    terrain_type character varying NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    x integer NOT NULL,
    y integer NOT NULL,
    zone character varying NOT NULL
);


--
-- Name: map_tile_templates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.map_tile_templates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: map_tile_templates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.map_tile_templates_id_seq OWNED BY public.map_tile_templates.id;


--
-- Name: movement_commands; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.movement_commands (
    id bigint NOT NULL,
    action_key character varying,
    character_id bigint NOT NULL,
    completed_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    direction character varying NOT NULL,
    ends_at timestamp(6) without time zone,
    error_message character varying,
    failed_at timestamp(6) without time zone,
    from_x integer NOT NULL,
    from_y integer NOT NULL,
    latency_ms integer DEFAULT 0 NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    predicted_x integer,
    predicted_y integer,
    processed_at timestamp(6) without time zone,
    started_at timestamp(6) without time zone,
    status integer DEFAULT 0 NOT NULL,
    target_x integer NOT NULL,
    target_y integer NOT NULL,
    travel_seconds integer NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    zone_id bigint NOT NULL
);


--
-- Name: movement_commands_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.movement_commands_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: movement_commands_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.movement_commands_id_seq OWNED BY public.movement_commands.id;


--
-- Name: npc_templates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.npc_templates (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    dialogue text NOT NULL,
    level integer DEFAULT 1 NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    name character varying NOT NULL,
    npc_key character varying,
    role character varying NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: npc_templates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.npc_templates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: npc_templates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.npc_templates_id_seq OWNED BY public.npc_templates.id;


--
-- Name: roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.roles (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    name character varying NOT NULL,
    resource_id bigint,
    resource_type character varying,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: roles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.roles_id_seq OWNED BY public.roles.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: shop_accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.shop_accounts (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    location_id bigint NOT NULL,
    location_type character varying NOT NULL,
    nv_balance numeric(12,2) NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT shop_accounts_bounded_balance CHECK (((nv_balance >= (0)::numeric) AND (nv_balance < ('10000000000'::bigint)::numeric))),
    CONSTRAINT shop_accounts_location_type CHECK (((location_type)::text = ANY (ARRAY[('CityHotspot'::character varying)::text, ('TileBuilding'::character varying)::text])))
);


--
-- Name: shop_accounts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.shop_accounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: shop_accounts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.shop_accounts_id_seq OWNED BY public.shop_accounts.id;


--
-- Name: shop_stocks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.shop_stocks (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    current integer NOT NULL,
    item_template_id bigint NOT NULL,
    maximum integer,
    shop_account_id bigint NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    CONSTRAINT shop_stocks_bounded_capacity CHECK (((maximum IS NULL) OR ((maximum >= 0) AND (current <= maximum)))),
    CONSTRAINT shop_stocks_nonnegative_current CHECK ((current >= 0))
);


--
-- Name: shop_stocks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.shop_stocks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: shop_stocks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.shop_stocks_id_seq OWNED BY public.shop_stocks.id;


--
-- Name: spawn_points; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.spawn_points (
    id bigint NOT NULL,
    city_key character varying,
    created_at timestamp(6) without time zone NOT NULL,
    default_entry boolean DEFAULT false NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    x integer NOT NULL,
    y integer NOT NULL,
    zone_id bigint NOT NULL
);


--
-- Name: spawn_points_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.spawn_points_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: spawn_points_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.spawn_points_id_seq OWNED BY public.spawn_points.id;


--
-- Name: tile_buildings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tile_buildings (
    id bigint NOT NULL,
    active boolean DEFAULT true NOT NULL,
    building_key character varying NOT NULL,
    building_type character varying DEFAULT 'city'::character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    destination_x integer,
    destination_y integer,
    destination_zone_id bigint,
    icon character varying DEFAULT '🏙️'::character varying,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    name character varying NOT NULL,
    required_level integer DEFAULT 1 NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    x integer NOT NULL,
    y integer NOT NULL,
    zone character varying NOT NULL
);


--
-- Name: tile_buildings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tile_buildings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tile_buildings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tile_buildings_id_seq OWNED BY public.tile_buildings.id;


--
-- Name: tile_npcs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tile_npcs (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    current_hp integer,
    defeated_at timestamp(6) without time zone,
    defeated_by_id bigint,
    level integer DEFAULT 1 NOT NULL,
    max_hp integer,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    npc_key character varying NOT NULL,
    npc_role character varying DEFAULT 'hostile'::character varying NOT NULL,
    npc_template_id bigint NOT NULL,
    respawns_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone NOT NULL,
    x integer NOT NULL,
    y integer NOT NULL,
    zone character varying NOT NULL
);


--
-- Name: tile_npcs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tile_npcs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tile_npcs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tile_npcs_id_seq OWNED BY public.tile_npcs.id;


--
-- Name: user_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_sessions (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    device_id character varying NOT NULL,
    last_seen_at timestamp(6) without time zone,
    signed_in_at timestamp(6) without time zone NOT NULL,
    signed_out_at timestamp(6) without time zone,
    updated_at timestamp(6) without time zone NOT NULL,
    user_id bigint NOT NULL
);


--
-- Name: user_sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_sessions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_sessions_id_seq OWNED BY public.user_sessions.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    chat_mute_reason character varying,
    chat_muted_until timestamp(6) without time zone,
    confirmation_sent_at timestamp(6) without time zone,
    confirmation_token character varying,
    confirmed_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    current_sign_in_at timestamp(6) without time zone,
    current_sign_in_ip inet,
    email character varying DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying DEFAULT ''::character varying NOT NULL,
    last_seen_at timestamp(6) without time zone,
    last_sign_in_at timestamp(6) without time zone,
    last_sign_in_ip inet,
    profile_name character varying NOT NULL,
    remember_created_at timestamp(6) without time zone,
    reset_password_sent_at timestamp(6) without time zone,
    reset_password_token character varying,
    sign_in_count integer DEFAULT 0 NOT NULL,
    suspended_until timestamp(6) without time zone,
    unconfirmed_email character varying,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: users_roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users_roles (
    role_id bigint NOT NULL,
    user_id bigint NOT NULL
);


--
-- Name: world_action_offers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.world_action_offers (
    id bigint NOT NULL,
    accepted_at timestamp(6) without time zone,
    action_key character varying NOT NULL,
    action_type character varying NOT NULL,
    character_id bigint NOT NULL,
    completed_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    error_message character varying,
    expires_at timestamp(6) without time zone NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    status integer DEFAULT 0 NOT NULL,
    target_id bigint,
    target_type character varying,
    updated_at timestamp(6) without time zone NOT NULL,
    x integer NOT NULL,
    y integer NOT NULL,
    zone_id bigint NOT NULL
);


--
-- Name: world_action_offers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.world_action_offers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: world_action_offers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.world_action_offers_id_seq OWNED BY public.world_action_offers.id;


--
-- Name: zones; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.zones (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    height integer DEFAULT 32 NOT NULL,
    location_type character varying DEFAULT 'outdoor'::character varying NOT NULL,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    name character varying NOT NULL,
    turn_counter integer DEFAULT 1 NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    width integer DEFAULT 32 NOT NULL
);


--
-- Name: zones_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.zones_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: zones_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.zones_id_seq OWNED BY public.zones.id;


--
-- Name: airship_journeys id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.airship_journeys ALTER COLUMN id SET DEFAULT nextval('public.airship_journeys_id_seq'::regclass);


--
-- Name: arena_applications id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.arena_applications ALTER COLUMN id SET DEFAULT nextval('public.arena_applications_id_seq'::regclass);


--
-- Name: arena_matches id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.arena_matches ALTER COLUMN id SET DEFAULT nextval('public.arena_matches_id_seq'::regclass);


--
-- Name: arena_participations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.arena_participations ALTER COLUMN id SET DEFAULT nextval('public.arena_participations_id_seq'::regclass);


--
-- Name: arena_rooms id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.arena_rooms ALTER COLUMN id SET DEFAULT nextval('public.arena_rooms_id_seq'::regclass);


--
-- Name: character_injuries id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.character_injuries ALTER COLUMN id SET DEFAULT nextval('public.character_injuries_id_seq'::regclass);


--
-- Name: character_licenses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.character_licenses ALTER COLUMN id SET DEFAULT nextval('public.character_licenses_id_seq'::regclass);


--
-- Name: character_positions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.character_positions ALTER COLUMN id SET DEFAULT nextval('public.character_positions_id_seq'::regclass);


--
-- Name: characters id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.characters ALTER COLUMN id SET DEFAULT nextval('public.characters_id_seq'::regclass);


--
-- Name: chat_channel_memberships id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_channel_memberships ALTER COLUMN id SET DEFAULT nextval('public.chat_channel_memberships_id_seq'::regclass);


--
-- Name: chat_channels id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_channels ALTER COLUMN id SET DEFAULT nextval('public.chat_channels_id_seq'::regclass);


--
-- Name: chat_messages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_messages ALTER COLUMN id SET DEFAULT nextval('public.chat_messages_id_seq'::regclass);


--
-- Name: city_hotspots id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.city_hotspots ALTER COLUMN id SET DEFAULT nextval('public.city_hotspots_id_seq'::regclass);


--
-- Name: combat_log_entries id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.combat_log_entries ALTER COLUMN id SET DEFAULT nextval('public.combat_log_entries_id_seq'::regclass);


--
-- Name: currency_transactions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.currency_transactions ALTER COLUMN id SET DEFAULT nextval('public.currency_transactions_id_seq'::regclass);


--
-- Name: currency_wallets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.currency_wallets ALTER COLUMN id SET DEFAULT nextval('public.currency_wallets_id_seq'::regclass);


--
-- Name: game_events id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.game_events ALTER COLUMN id SET DEFAULT nextval('public.game_events_id_seq'::regclass);


--
-- Name: ignore_list_entries id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ignore_list_entries ALTER COLUMN id SET DEFAULT nextval('public.ignore_list_entries_id_seq'::regclass);


--
-- Name: injury_treatments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.injury_treatments ALTER COLUMN id SET DEFAULT nextval('public.injury_treatments_id_seq'::regclass);


--
-- Name: inventories id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventories ALTER COLUMN id SET DEFAULT nextval('public.inventories_id_seq'::regclass);


--
-- Name: inventory_items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_items ALTER COLUMN id SET DEFAULT nextval('public.inventory_items_id_seq'::regclass);


--
-- Name: item_templates id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.item_templates ALTER COLUMN id SET DEFAULT nextval('public.item_templates_id_seq'::regclass);


--
-- Name: management_audit_events id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.management_audit_events ALTER COLUMN id SET DEFAULT nextval('public.management_audit_events_id_seq'::regclass);


--
-- Name: map_tile_templates id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.map_tile_templates ALTER COLUMN id SET DEFAULT nextval('public.map_tile_templates_id_seq'::regclass);


--
-- Name: movement_commands id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.movement_commands ALTER COLUMN id SET DEFAULT nextval('public.movement_commands_id_seq'::regclass);


--
-- Name: npc_templates id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.npc_templates ALTER COLUMN id SET DEFAULT nextval('public.npc_templates_id_seq'::regclass);


--
-- Name: roles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles ALTER COLUMN id SET DEFAULT nextval('public.roles_id_seq'::regclass);


--
-- Name: shop_accounts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shop_accounts ALTER COLUMN id SET DEFAULT nextval('public.shop_accounts_id_seq'::regclass);


--
-- Name: shop_stocks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shop_stocks ALTER COLUMN id SET DEFAULT nextval('public.shop_stocks_id_seq'::regclass);


--
-- Name: spawn_points id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.spawn_points ALTER COLUMN id SET DEFAULT nextval('public.spawn_points_id_seq'::regclass);


--
-- Name: tile_buildings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tile_buildings ALTER COLUMN id SET DEFAULT nextval('public.tile_buildings_id_seq'::regclass);


--
-- Name: tile_npcs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tile_npcs ALTER COLUMN id SET DEFAULT nextval('public.tile_npcs_id_seq'::regclass);


--
-- Name: user_sessions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_sessions ALTER COLUMN id SET DEFAULT nextval('public.user_sessions_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: world_action_offers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.world_action_offers ALTER COLUMN id SET DEFAULT nextval('public.world_action_offers_id_seq'::regclass);


--
-- Name: zones id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.zones ALTER COLUMN id SET DEFAULT nextval('public.zones_id_seq'::regclass);


--
-- Name: airship_journeys airship_journeys_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.airship_journeys
    ADD CONSTRAINT airship_journeys_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: arena_applications arena_applications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.arena_applications
    ADD CONSTRAINT arena_applications_pkey PRIMARY KEY (id);


--
-- Name: arena_matches arena_matches_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.arena_matches
    ADD CONSTRAINT arena_matches_pkey PRIMARY KEY (id);


--
-- Name: arena_participations arena_participations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.arena_participations
    ADD CONSTRAINT arena_participations_pkey PRIMARY KEY (id);


--
-- Name: arena_rooms arena_rooms_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.arena_rooms
    ADD CONSTRAINT arena_rooms_pkey PRIMARY KEY (id);


--
-- Name: character_injuries character_injuries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.character_injuries
    ADD CONSTRAINT character_injuries_pkey PRIMARY KEY (id);


--
-- Name: character_licenses character_licenses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.character_licenses
    ADD CONSTRAINT character_licenses_pkey PRIMARY KEY (id);


--
-- Name: character_positions character_positions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.character_positions
    ADD CONSTRAINT character_positions_pkey PRIMARY KEY (id);


--
-- Name: characters characters_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.characters
    ADD CONSTRAINT characters_pkey PRIMARY KEY (id);


--
-- Name: chat_channel_memberships chat_channel_memberships_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_channel_memberships
    ADD CONSTRAINT chat_channel_memberships_pkey PRIMARY KEY (id);


--
-- Name: chat_channels chat_channels_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_channels
    ADD CONSTRAINT chat_channels_pkey PRIMARY KEY (id);


--
-- Name: chat_messages chat_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_messages
    ADD CONSTRAINT chat_messages_pkey PRIMARY KEY (id);


--
-- Name: city_hotspots city_hotspots_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.city_hotspots
    ADD CONSTRAINT city_hotspots_pkey PRIMARY KEY (id);


--
-- Name: combat_log_entries combat_log_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.combat_log_entries
    ADD CONSTRAINT combat_log_entries_pkey PRIMARY KEY (id);


--
-- Name: currency_transactions currency_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.currency_transactions
    ADD CONSTRAINT currency_transactions_pkey PRIMARY KEY (id);


--
-- Name: currency_wallets currency_wallets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.currency_wallets
    ADD CONSTRAINT currency_wallets_pkey PRIMARY KEY (id);


--
-- Name: game_events game_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.game_events
    ADD CONSTRAINT game_events_pkey PRIMARY KEY (id);


--
-- Name: ignore_list_entries ignore_list_entries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ignore_list_entries
    ADD CONSTRAINT ignore_list_entries_pkey PRIMARY KEY (id);


--
-- Name: injury_treatments injury_treatments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.injury_treatments
    ADD CONSTRAINT injury_treatments_pkey PRIMARY KEY (id);


--
-- Name: inventories inventories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventories
    ADD CONSTRAINT inventories_pkey PRIMARY KEY (id);


--
-- Name: inventory_items inventory_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_items
    ADD CONSTRAINT inventory_items_pkey PRIMARY KEY (id);


--
-- Name: item_templates item_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.item_templates
    ADD CONSTRAINT item_templates_pkey PRIMARY KEY (id);


--
-- Name: management_audit_events management_audit_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.management_audit_events
    ADD CONSTRAINT management_audit_events_pkey PRIMARY KEY (id);


--
-- Name: map_tile_templates map_tile_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.map_tile_templates
    ADD CONSTRAINT map_tile_templates_pkey PRIMARY KEY (id);


--
-- Name: movement_commands movement_commands_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.movement_commands
    ADD CONSTRAINT movement_commands_pkey PRIMARY KEY (id);


--
-- Name: npc_templates npc_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.npc_templates
    ADD CONSTRAINT npc_templates_pkey PRIMARY KEY (id);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: shop_accounts shop_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shop_accounts
    ADD CONSTRAINT shop_accounts_pkey PRIMARY KEY (id);


--
-- Name: shop_stocks shop_stocks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shop_stocks
    ADD CONSTRAINT shop_stocks_pkey PRIMARY KEY (id);


--
-- Name: spawn_points spawn_points_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.spawn_points
    ADD CONSTRAINT spawn_points_pkey PRIMARY KEY (id);


--
-- Name: tile_buildings tile_buildings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tile_buildings
    ADD CONSTRAINT tile_buildings_pkey PRIMARY KEY (id);


--
-- Name: tile_npcs tile_npcs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tile_npcs
    ADD CONSTRAINT tile_npcs_pkey PRIMARY KEY (id);


--
-- Name: user_sessions user_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_sessions
    ADD CONSTRAINT user_sessions_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: world_action_offers world_action_offers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.world_action_offers
    ADD CONSTRAINT world_action_offers_pkey PRIMARY KEY (id);


--
-- Name: zones zones_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.zones
    ADD CONSTRAINT zones_pkey PRIMARY KEY (id);


--
-- Name: idx_arena_apps_npc; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_arena_apps_npc ON public.arena_applications USING btree (arena_room_id, npc_template_id) WHERE (npc_template_id IS NOT NULL);


--
-- Name: idx_inventory_equipped_slot; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_inventory_equipped_slot ON public.inventory_items USING btree (inventory_id, equipped, equipment_slot);


--
-- Name: idx_on_character_id_kind_expires_at_33fede8863; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_on_character_id_kind_expires_at_33fede8863 ON public.character_licenses USING btree (character_id, kind, expires_at);


--
-- Name: index_aboard_airship_flight; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_aboard_airship_flight ON public.airship_journeys USING btree (route_key, departs_at) WHERE (status = 0);


--
-- Name: index_airship_journeys_on_boarding_offer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_airship_journeys_on_boarding_offer_id ON public.airship_journeys USING btree (boarding_offer_id);


--
-- Name: index_airship_journeys_on_character_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_airship_journeys_on_character_id ON public.airship_journeys USING btree (character_id);


--
-- Name: index_airship_journeys_on_destination_zone_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_airship_journeys_on_destination_zone_id ON public.airship_journeys USING btree (destination_zone_id);


--
-- Name: index_airship_journeys_on_last_position_zone_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_airship_journeys_on_last_position_zone_id ON public.airship_journeys USING btree (last_position_zone_id);


--
-- Name: index_airship_journeys_on_source_zone_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_airship_journeys_on_source_zone_id ON public.airship_journeys USING btree (source_zone_id);


--
-- Name: index_arena_applications_on_applicant_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_arena_applications_on_applicant_id ON public.arena_applications USING btree (applicant_id);


--
-- Name: index_arena_applications_on_arena_match_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_arena_applications_on_arena_match_id ON public.arena_applications USING btree (arena_match_id);


--
-- Name: index_arena_applications_on_arena_room_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_arena_applications_on_arena_room_id ON public.arena_applications USING btree (arena_room_id);


--
-- Name: index_arena_applications_on_arena_room_id_and_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_arena_applications_on_arena_room_id_and_status ON public.arena_applications USING btree (arena_room_id, status);


--
-- Name: index_arena_applications_on_fight_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_arena_applications_on_fight_type ON public.arena_applications USING btree (fight_type);


--
-- Name: index_arena_applications_on_matched_with_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_arena_applications_on_matched_with_id ON public.arena_applications USING btree (matched_with_id);


--
-- Name: index_arena_applications_on_npc_template_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_arena_applications_on_npc_template_id ON public.arena_applications USING btree (npc_template_id);


--
-- Name: index_arena_applications_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_arena_applications_on_status ON public.arena_applications USING btree (status);


--
-- Name: index_arena_matches_on_arena_room_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_arena_matches_on_arena_room_id ON public.arena_matches USING btree (arena_room_id);


--
-- Name: index_arena_matches_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_arena_matches_on_status ON public.arena_matches USING btree (status);


--
-- Name: index_arena_matches_on_timeout_check; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_arena_matches_on_timeout_check ON public.arena_matches USING btree (status, current_turn_started_at) WHERE (status = 2);


--
-- Name: index_arena_matches_on_zone_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_arena_matches_on_zone_id ON public.arena_matches USING btree (zone_id);


--
-- Name: index_arena_participants_on_match_and_character; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_arena_participants_on_match_and_character ON public.arena_participations USING btree (arena_match_id, character_id);


--
-- Name: index_arena_participations_on_arena_match_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_arena_participations_on_arena_match_id ON public.arena_participations USING btree (arena_match_id);


--
-- Name: index_arena_participations_on_character_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_arena_participations_on_character_id ON public.arena_participations USING btree (character_id);


--
-- Name: index_arena_participations_on_npc_template_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_arena_participations_on_npc_template_id ON public.arena_participations USING btree (npc_template_id);


--
-- Name: index_arena_participations_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_arena_participations_on_user_id ON public.arena_participations USING btree (user_id);


--
-- Name: index_arena_rooms_on_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_arena_rooms_on_active ON public.arena_rooms USING btree (active);


--
-- Name: index_arena_rooms_on_room_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_arena_rooms_on_room_type ON public.arena_rooms USING btree (room_type);


--
-- Name: index_arena_rooms_on_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_arena_rooms_on_slug ON public.arena_rooms USING btree (slug);


--
-- Name: index_arena_rooms_on_zone_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_arena_rooms_on_zone_id ON public.arena_rooms USING btree (zone_id);


--
-- Name: index_character_injuries_on_arena_match_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_character_injuries_on_arena_match_id ON public.character_injuries USING btree (arena_match_id);


--
-- Name: index_character_injuries_on_arena_match_id_and_character_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_character_injuries_on_arena_match_id_and_character_id ON public.character_injuries USING btree (arena_match_id, character_id);


--
-- Name: index_character_injuries_on_character_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_character_injuries_on_character_id ON public.character_injuries USING btree (character_id);


--
-- Name: index_character_licenses_on_character_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_character_licenses_on_character_id ON public.character_licenses USING btree (character_id);


--
-- Name: index_character_licenses_on_item_template_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_character_licenses_on_item_template_id ON public.character_licenses USING btree (item_template_id);


--
-- Name: index_character_licenses_on_world_action_offer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_character_licenses_on_world_action_offer_id ON public.character_licenses USING btree (world_action_offer_id);


--
-- Name: index_character_positions_on_character_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_character_positions_on_character_id ON public.character_positions USING btree (character_id);


--
-- Name: index_character_positions_on_zone_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_character_positions_on_zone_id ON public.character_positions USING btree (zone_id);


--
-- Name: index_character_positions_on_zone_id_and_x_and_y; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_character_positions_on_zone_id_and_x_and_y ON public.character_positions USING btree (zone_id, x, y);


--
-- Name: index_characters_on_combat_skill_points; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_characters_on_combat_skill_points ON public.characters USING btree (combat_skill_points) WHERE (combat_skill_points > 0);


--
-- Name: index_characters_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_characters_on_name ON public.characters USING btree (name);


--
-- Name: index_characters_on_peace_skill_points; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_characters_on_peace_skill_points ON public.characters USING btree (peace_skill_points) WHERE (peace_skill_points > 0);


--
-- Name: index_characters_on_perk_points; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_characters_on_perk_points ON public.characters USING btree (perk_points) WHERE (perk_points > 0);


--
-- Name: index_characters_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_characters_on_user_id ON public.characters USING btree (user_id);


--
-- Name: index_chat_channel_memberships_on_chat_channel_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_chat_channel_memberships_on_chat_channel_id ON public.chat_channel_memberships USING btree (chat_channel_id);


--
-- Name: index_chat_channel_memberships_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_chat_channel_memberships_on_user_id ON public.chat_channel_memberships USING btree (user_id);


--
-- Name: index_chat_channels_on_channel_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_chat_channels_on_channel_type ON public.chat_channels USING btree (channel_type);


--
-- Name: index_chat_channels_on_creator_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_chat_channels_on_creator_id ON public.chat_channels USING btree (creator_id);


--
-- Name: index_chat_channels_on_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_chat_channels_on_slug ON public.chat_channels USING btree (slug);


--
-- Name: index_chat_memberships_on_channel_and_user; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_chat_memberships_on_channel_and_user ON public.chat_channel_memberships USING btree (chat_channel_id, user_id);


--
-- Name: index_chat_messages_on_chat_channel_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_chat_messages_on_chat_channel_id ON public.chat_messages USING btree (chat_channel_id);


--
-- Name: index_chat_messages_on_chat_channel_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_chat_messages_on_chat_channel_id_and_created_at ON public.chat_messages USING btree (chat_channel_id, created_at);


--
-- Name: index_chat_messages_on_sender_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_chat_messages_on_sender_id ON public.chat_messages USING btree (sender_id);


--
-- Name: index_city_hotspots_on_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_city_hotspots_on_active ON public.city_hotspots USING btree (active);


--
-- Name: index_city_hotspots_on_destination_zone_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_city_hotspots_on_destination_zone_id ON public.city_hotspots USING btree (destination_zone_id);


--
-- Name: index_city_hotspots_on_hotspot_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_city_hotspots_on_hotspot_type ON public.city_hotspots USING btree (hotspot_type);


--
-- Name: index_city_hotspots_on_zone_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_city_hotspots_on_zone_id ON public.city_hotspots USING btree (zone_id);


--
-- Name: index_city_hotspots_on_zone_id_and_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_city_hotspots_on_zone_id_and_key ON public.city_hotspots USING btree (zone_id, key);


--
-- Name: index_combat_log_entries_on_actor_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_combat_log_entries_on_actor_id ON public.combat_log_entries USING btree (actor_id);


--
-- Name: index_combat_log_entries_on_arena_match_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_combat_log_entries_on_arena_match_id ON public.combat_log_entries USING btree (arena_match_id);


--
-- Name: index_combat_log_entries_on_log_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_combat_log_entries_on_log_type ON public.combat_log_entries USING btree (log_type);


--
-- Name: index_combat_log_entries_on_tags; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_combat_log_entries_on_tags ON public.combat_log_entries USING gin (tags);


--
-- Name: index_combat_log_entries_on_target_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_combat_log_entries_on_target_id ON public.combat_log_entries USING btree (target_id);


--
-- Name: index_combat_logs_on_arena_match_and_log_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_combat_logs_on_arena_match_and_log_type ON public.combat_log_entries USING btree (arena_match_id, log_type);


--
-- Name: index_combat_logs_on_arena_match_round_sequence; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_combat_logs_on_arena_match_round_sequence ON public.combat_log_entries USING btree (arena_match_id, round_number, sequence);


--
-- Name: index_currency_transactions_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_currency_transactions_on_created_at ON public.currency_transactions USING btree (created_at);


--
-- Name: index_currency_transactions_on_currency_wallet_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_currency_transactions_on_currency_wallet_id ON public.currency_transactions USING btree (currency_wallet_id);


--
-- Name: index_currency_transactions_on_shop_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_currency_transactions_on_shop_account_id ON public.currency_transactions USING btree (shop_account_id);


--
-- Name: index_currency_transactions_unique_shop_offer; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_currency_transactions_unique_shop_offer ON public.currency_transactions USING btree (shop_offer_id) WHERE (shop_offer_id IS NOT NULL);


--
-- Name: index_currency_wallets_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_currency_wallets_on_user_id ON public.currency_wallets USING btree (user_id);


--
-- Name: index_game_events_on_event_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_game_events_on_event_key ON public.game_events USING btree (event_key);


--
-- Name: index_game_events_on_occurred_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_game_events_on_occurred_at ON public.game_events USING btree (occurred_at);


--
-- Name: index_game_events_on_recipient_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_game_events_on_recipient_id ON public.game_events USING btree (recipient_id);


--
-- Name: index_game_events_on_recipient_id_and_occurred_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_game_events_on_recipient_id_and_occurred_at ON public.game_events USING btree (recipient_id, occurred_at);


--
-- Name: index_ignore_entries_on_user_and_target; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_ignore_entries_on_user_and_target ON public.ignore_list_entries USING btree (user_id, ignored_user_id);


--
-- Name: index_ignore_list_entries_on_ignored_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ignore_list_entries_on_ignored_user_id ON public.ignore_list_entries USING btree (ignored_user_id);


--
-- Name: index_ignore_list_entries_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ignore_list_entries_on_user_id ON public.ignore_list_entries USING btree (user_id);


--
-- Name: index_injury_treatments_on_character_injury_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_injury_treatments_on_character_injury_id ON public.injury_treatments USING btree (character_injury_id);


--
-- Name: index_injury_treatments_on_healer_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_injury_treatments_on_healer_id ON public.injury_treatments USING btree (healer_id);


--
-- Name: index_injury_treatments_on_inventory_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_injury_treatments_on_inventory_item_id ON public.injury_treatments USING btree (inventory_item_id);


--
-- Name: index_inventories_on_character_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_inventories_on_character_id ON public.inventories USING btree (character_id);


--
-- Name: index_inventory_items_on_inventory_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inventory_items_on_inventory_id ON public.inventory_items USING btree (inventory_id);


--
-- Name: index_inventory_items_on_inventory_id_and_slot_kind; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inventory_items_on_inventory_id_and_slot_kind ON public.inventory_items USING btree (inventory_id, slot_kind);


--
-- Name: index_inventory_items_on_item_template_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_inventory_items_on_item_template_id ON public.inventory_items USING btree (item_template_id);


--
-- Name: index_item_templates_on_item_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_item_templates_on_item_type ON public.item_templates USING btree (item_type);


--
-- Name: index_item_templates_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_item_templates_on_key ON public.item_templates USING btree (key);


--
-- Name: index_item_templates_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_item_templates_on_name ON public.item_templates USING btree (name);


--
-- Name: index_item_templates_on_slot; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_item_templates_on_slot ON public.item_templates USING btree (slot);


--
-- Name: index_management_audit_events_on_actor_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_management_audit_events_on_actor_id_and_created_at ON public.management_audit_events USING btree (actor_id, created_at);


--
-- Name: index_management_audit_events_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_management_audit_events_on_created_at ON public.management_audit_events USING btree (created_at);


--
-- Name: index_management_audit_events_on_record_type_and_record_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_management_audit_events_on_record_type_and_record_id ON public.management_audit_events USING btree (record_type, record_id);


--
-- Name: index_map_tile_templates_on_zone_and_x_and_y; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_map_tile_templates_on_zone_and_x_and_y ON public.map_tile_templates USING btree (zone, x, y);


--
-- Name: index_movement_commands_on_action_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_movement_commands_on_action_key ON public.movement_commands USING btree (action_key);


--
-- Name: index_movement_commands_on_character_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_movement_commands_on_character_id ON public.movement_commands USING btree (character_id);


--
-- Name: index_movement_commands_on_character_status_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_movement_commands_on_character_status_created ON public.movement_commands USING btree (character_id, status, created_at);


--
-- Name: index_movement_commands_on_character_status_ends; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_movement_commands_on_character_status_ends ON public.movement_commands USING btree (character_id, status, ends_at);


--
-- Name: index_movement_commands_on_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_movement_commands_on_created_at ON public.movement_commands USING btree (created_at);


--
-- Name: index_movement_commands_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_movement_commands_on_status ON public.movement_commands USING btree (status);


--
-- Name: index_movement_commands_on_zone_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_movement_commands_on_zone_id ON public.movement_commands USING btree (zone_id);


--
-- Name: index_npc_templates_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_npc_templates_on_name ON public.npc_templates USING btree (name);


--
-- Name: index_npc_templates_on_npc_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_npc_templates_on_npc_key ON public.npc_templates USING btree (npc_key);


--
-- Name: index_npc_templates_on_role; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_npc_templates_on_role ON public.npc_templates USING btree (role);


--
-- Name: index_one_aboard_airship_journey_per_character; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_one_aboard_airship_journey_per_character ON public.airship_journeys USING btree (character_id) WHERE (status = 0);


--
-- Name: index_roles_on_name_and_resource_type_and_resource_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_roles_on_name_and_resource_type_and_resource_id ON public.roles USING btree (name, resource_type, resource_id);


--
-- Name: index_roles_on_resource; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_roles_on_resource ON public.roles USING btree (resource_type, resource_id);


--
-- Name: index_shop_accounts_on_location; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_shop_accounts_on_location ON public.shop_accounts USING btree (location_type, location_id);


--
-- Name: index_shop_stocks_on_item_template_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shop_stocks_on_item_template_id ON public.shop_stocks USING btree (item_template_id);


--
-- Name: index_shop_stocks_on_shop_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_shop_stocks_on_shop_account_id ON public.shop_stocks USING btree (shop_account_id);


--
-- Name: index_shop_stocks_on_shop_account_id_and_item_template_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_shop_stocks_on_shop_account_id_and_item_template_id ON public.shop_stocks USING btree (shop_account_id, item_template_id);


--
-- Name: index_spawn_points_on_zone_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_spawn_points_on_zone_id ON public.spawn_points USING btree (zone_id);


--
-- Name: index_tile_buildings_on_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tile_buildings_on_active ON public.tile_buildings USING btree (active);


--
-- Name: index_tile_buildings_on_building_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_tile_buildings_on_building_key ON public.tile_buildings USING btree (building_key);


--
-- Name: index_tile_buildings_on_building_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tile_buildings_on_building_type ON public.tile_buildings USING btree (building_type);


--
-- Name: index_tile_buildings_on_destination_zone_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tile_buildings_on_destination_zone_id ON public.tile_buildings USING btree (destination_zone_id);


--
-- Name: index_tile_buildings_on_zone_and_x_and_y; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_tile_buildings_on_zone_and_x_and_y ON public.tile_buildings USING btree (zone, x, y);


--
-- Name: index_tile_npcs_on_defeated_by_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tile_npcs_on_defeated_by_id ON public.tile_npcs USING btree (defeated_by_id);


--
-- Name: index_tile_npcs_on_npc_role; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tile_npcs_on_npc_role ON public.tile_npcs USING btree (npc_role);


--
-- Name: index_tile_npcs_on_npc_template_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tile_npcs_on_npc_template_id ON public.tile_npcs USING btree (npc_template_id);


--
-- Name: index_tile_npcs_on_respawns_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tile_npcs_on_respawns_at ON public.tile_npcs USING btree (respawns_at);


--
-- Name: index_tile_npcs_on_zone_and_x_and_y; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_tile_npcs_on_zone_and_x_and_y ON public.tile_npcs USING btree (zone, x, y);


--
-- Name: index_user_sessions_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_sessions_on_user_id ON public.user_sessions USING btree (user_id);


--
-- Name: index_user_sessions_on_user_id_and_device_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_user_sessions_on_user_id_and_device_id ON public.user_sessions USING btree (user_id, device_id);


--
-- Name: index_users_on_confirmation_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_confirmation_token ON public.users USING btree (confirmation_token);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_email ON public.users USING btree (email);


--
-- Name: index_users_on_profile_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_profile_name ON public.users USING btree (profile_name);


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON public.users USING btree (reset_password_token);


--
-- Name: index_users_on_suspended_until; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_suspended_until ON public.users USING btree (suspended_until);


--
-- Name: index_users_roles_on_role_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_roles_on_role_id ON public.users_roles USING btree (role_id);


--
-- Name: index_users_roles_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_roles_on_user_id ON public.users_roles USING btree (user_id);


--
-- Name: index_users_roles_on_user_id_and_role_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_roles_on_user_id_and_role_id ON public.users_roles USING btree (user_id, role_id);


--
-- Name: index_world_action_offers_on_action_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_world_action_offers_on_action_key ON public.world_action_offers USING btree (action_key);


--
-- Name: index_world_action_offers_on_character_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_world_action_offers_on_character_id ON public.world_action_offers USING btree (character_id);


--
-- Name: index_world_action_offers_on_character_status_expires; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_world_action_offers_on_character_status_expires ON public.world_action_offers USING btree (character_id, status, expires_at);


--
-- Name: index_world_action_offers_on_character_tile_action_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_world_action_offers_on_character_tile_action_status ON public.world_action_offers USING btree (character_id, zone_id, x, y, action_type, status);


--
-- Name: index_world_action_offers_on_target; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_world_action_offers_on_target ON public.world_action_offers USING btree (target_type, target_id);


--
-- Name: index_world_action_offers_on_zone_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_world_action_offers_on_zone_id ON public.world_action_offers USING btree (zone_id);


--
-- Name: index_zones_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_zones_on_name ON public.zones USING btree (name);


--
-- Name: one_pending_injury_treatment; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX one_pending_injury_treatment ON public.injury_treatments USING btree (character_injury_id, healer_id) WHERE ((status)::text = 'pending'::text);


--
-- Name: currency_transactions currency_transactions_shop_receipt_guard; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER currency_transactions_shop_receipt_guard AFTER INSERT OR DELETE OR UPDATE ON public.currency_transactions FOR EACH ROW EXECUTE FUNCTION public.guard_shop_currency_receipt();


--
-- Name: arena_applications fk_rails_0247d600f9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.arena_applications
    ADD CONSTRAINT fk_rails_0247d600f9 FOREIGN KEY (arena_room_id) REFERENCES public.arena_rooms(id);


--
-- Name: ignore_list_entries fk_rails_040bb17c50; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ignore_list_entries
    ADD CONSTRAINT fk_rails_040bb17c50 FOREIGN KEY (ignored_user_id) REFERENCES public.users(id);


--
-- Name: arena_participations fk_rails_0569923360; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.arena_participations
    ADD CONSTRAINT fk_rails_0569923360 FOREIGN KEY (arena_match_id) REFERENCES public.arena_matches(id);


--
-- Name: character_licenses fk_rails_098e4ad31f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.character_licenses
    ADD CONSTRAINT fk_rails_098e4ad31f FOREIGN KEY (world_action_offer_id) REFERENCES public.world_action_offers(id);


--
-- Name: injury_treatments fk_rails_0a06e99f5b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.injury_treatments
    ADD CONSTRAINT fk_rails_0a06e99f5b FOREIGN KEY (inventory_item_id) REFERENCES public.inventory_items(id);


--
-- Name: ignore_list_entries fk_rails_1cd6ca5120; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ignore_list_entries
    ADD CONSTRAINT fk_rails_1cd6ca5120 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: arena_participations fk_rails_1d11103f6c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.arena_participations
    ADD CONSTRAINT fk_rails_1d11103f6c FOREIGN KEY (character_id) REFERENCES public.characters(id);


--
-- Name: movement_commands fk_rails_1fd8341ac8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.movement_commands
    ADD CONSTRAINT fk_rails_1fd8341ac8 FOREIGN KEY (character_id) REFERENCES public.characters(id);


--
-- Name: arena_participations fk_rails_20a0031bdb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.arena_participations
    ADD CONSTRAINT fk_rails_20a0031bdb FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: airship_journeys fk_rails_24b42c2526; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.airship_journeys
    ADD CONSTRAINT fk_rails_24b42c2526 FOREIGN KEY (boarding_offer_id) REFERENCES public.world_action_offers(id);


--
-- Name: airship_journeys fk_rails_2be43be1a7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.airship_journeys
    ADD CONSTRAINT fk_rails_2be43be1a7 FOREIGN KEY (last_position_zone_id) REFERENCES public.zones(id);


--
-- Name: management_audit_events fk_rails_3187b4ecca; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.management_audit_events
    ADD CONSTRAINT fk_rails_3187b4ecca FOREIGN KEY (actor_id) REFERENCES public.users(id);


--
-- Name: city_hotspots fk_rails_329d2dee83; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.city_hotspots
    ADD CONSTRAINT fk_rails_329d2dee83 FOREIGN KEY (zone_id) REFERENCES public.zones(id);


--
-- Name: shop_stocks fk_rails_39a197bb1d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shop_stocks
    ADD CONSTRAINT fk_rails_39a197bb1d FOREIGN KEY (item_template_id) REFERENCES public.item_templates(id);


--
-- Name: character_injuries fk_rails_39ec66cdb9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.character_injuries
    ADD CONSTRAINT fk_rails_39ec66cdb9 FOREIGN KEY (character_id) REFERENCES public.characters(id);


--
-- Name: airship_journeys fk_rails_3a611d2232; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.airship_journeys
    ADD CONSTRAINT fk_rails_3a611d2232 FOREIGN KEY (destination_zone_id) REFERENCES public.zones(id);


--
-- Name: spawn_points fk_rails_42903a7408; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.spawn_points
    ADD CONSTRAINT fk_rails_42903a7408 FOREIGN KEY (zone_id) REFERENCES public.zones(id);


--
-- Name: inventory_items fk_rails_48ddeb9416; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_items
    ADD CONSTRAINT fk_rails_48ddeb9416 FOREIGN KEY (item_template_id) REFERENCES public.item_templates(id);


--
-- Name: users_roles fk_rails_4a41696df6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users_roles
    ADD CONSTRAINT fk_rails_4a41696df6 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: chat_channel_memberships fk_rails_4ba367990a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_channel_memberships
    ADD CONSTRAINT fk_rails_4ba367990a FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: arena_applications fk_rails_4c51de75d5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.arena_applications
    ADD CONSTRAINT fk_rails_4c51de75d5 FOREIGN KEY (npc_template_id) REFERENCES public.npc_templates(id);


--
-- Name: tile_buildings fk_rails_5331640dba; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tile_buildings
    ADD CONSTRAINT fk_rails_5331640dba FOREIGN KEY (destination_zone_id) REFERENCES public.zones(id);


--
-- Name: characters fk_rails_53a8ea746c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.characters
    ADD CONSTRAINT fk_rails_53a8ea746c FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: chat_channels fk_rails_5538763f60; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_channels
    ADD CONSTRAINT fk_rails_5538763f60 FOREIGN KEY (creator_id) REFERENCES public.users(id);


--
-- Name: currency_wallets fk_rails_55e59a9b93; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.currency_wallets
    ADD CONSTRAINT fk_rails_55e59a9b93 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: game_events fk_rails_592ecdf1ba; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.game_events
    ADD CONSTRAINT fk_rails_592ecdf1ba FOREIGN KEY (recipient_id) REFERENCES public.users(id);


--
-- Name: combat_log_entries fk_rails_5c1d87ffba; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.combat_log_entries
    ADD CONSTRAINT fk_rails_5c1d87ffba FOREIGN KEY (arena_match_id) REFERENCES public.arena_matches(id);


--
-- Name: chat_messages fk_rails_6223514182; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_messages
    ADD CONSTRAINT fk_rails_6223514182 FOREIGN KEY (sender_id) REFERENCES public.users(id);


--
-- Name: character_positions fk_rails_65a823c87b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.character_positions
    ADD CONSTRAINT fk_rails_65a823c87b FOREIGN KEY (character_id) REFERENCES public.characters(id);


--
-- Name: character_injuries fk_rails_660be36b82; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.character_injuries
    ADD CONSTRAINT fk_rails_660be36b82 FOREIGN KEY (arena_match_id) REFERENCES public.arena_matches(id);


--
-- Name: chat_messages fk_rails_66c73bb60c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_messages
    ADD CONSTRAINT fk_rails_66c73bb60c FOREIGN KEY (chat_channel_id) REFERENCES public.chat_channels(id);


--
-- Name: injury_treatments fk_rails_6a8f01d9ad; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.injury_treatments
    ADD CONSTRAINT fk_rails_6a8f01d9ad FOREIGN KEY (healer_id) REFERENCES public.characters(id);


--
-- Name: inventories fk_rails_6f10c29437; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventories
    ADD CONSTRAINT fk_rails_6f10c29437 FOREIGN KEY (character_id) REFERENCES public.characters(id);


--
-- Name: character_licenses fk_rails_7b3b9ec5f6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.character_licenses
    ADD CONSTRAINT fk_rails_7b3b9ec5f6 FOREIGN KEY (item_template_id) REFERENCES public.item_templates(id);


--
-- Name: world_action_offers fk_rails_854c4b4c5d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.world_action_offers
    ADD CONSTRAINT fk_rails_854c4b4c5d FOREIGN KEY (zone_id) REFERENCES public.zones(id);


--
-- Name: character_licenses fk_rails_91229fcb78; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.character_licenses
    ADD CONSTRAINT fk_rails_91229fcb78 FOREIGN KEY (character_id) REFERENCES public.characters(id);


--
-- Name: arena_rooms fk_rails_92717952c1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.arena_rooms
    ADD CONSTRAINT fk_rails_92717952c1 FOREIGN KEY (zone_id) REFERENCES public.zones(id);


--
-- Name: airship_journeys fk_rails_976522c506; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.airship_journeys
    ADD CONSTRAINT fk_rails_976522c506 FOREIGN KEY (source_zone_id) REFERENCES public.zones(id);


--
-- Name: user_sessions fk_rails_9fa262d742; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_sessions
    ADD CONSTRAINT fk_rails_9fa262d742 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: arena_applications fk_rails_a0addca969; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.arena_applications
    ADD CONSTRAINT fk_rails_a0addca969 FOREIGN KEY (matched_with_id) REFERENCES public.arena_applications(id);


--
-- Name: currency_transactions fk_rails_a3c55794b0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.currency_transactions
    ADD CONSTRAINT fk_rails_a3c55794b0 FOREIGN KEY (currency_wallet_id) REFERENCES public.currency_wallets(id);


--
-- Name: movement_commands fk_rails_a61bc1bb0f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.movement_commands
    ADD CONSTRAINT fk_rails_a61bc1bb0f FOREIGN KEY (zone_id) REFERENCES public.zones(id);


--
-- Name: inventory_items fk_rails_a7dc109dcc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_items
    ADD CONSTRAINT fk_rails_a7dc109dcc FOREIGN KEY (inventory_id) REFERENCES public.inventories(id);


--
-- Name: tile_npcs fk_rails_adcec41f13; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tile_npcs
    ADD CONSTRAINT fk_rails_adcec41f13 FOREIGN KEY (defeated_by_id) REFERENCES public.characters(id);


--
-- Name: chat_channel_memberships fk_rails_b2bb73e339; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_channel_memberships
    ADD CONSTRAINT fk_rails_b2bb73e339 FOREIGN KEY (chat_channel_id) REFERENCES public.chat_channels(id);


--
-- Name: currency_transactions fk_rails_b402acdf79; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.currency_transactions
    ADD CONSTRAINT fk_rails_b402acdf79 FOREIGN KEY (shop_offer_id) REFERENCES public.world_action_offers(id);


--
-- Name: injury_treatments fk_rails_b69c0c9b6d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.injury_treatments
    ADD CONSTRAINT fk_rails_b69c0c9b6d FOREIGN KEY (character_injury_id) REFERENCES public.character_injuries(id);


--
-- Name: shop_stocks fk_rails_b7ce5917f4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shop_stocks
    ADD CONSTRAINT fk_rails_b7ce5917f4 FOREIGN KEY (shop_account_id) REFERENCES public.shop_accounts(id);


--
-- Name: arena_applications fk_rails_ba252d0bfd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.arena_applications
    ADD CONSTRAINT fk_rails_ba252d0bfd FOREIGN KEY (applicant_id) REFERENCES public.characters(id);


--
-- Name: arena_matches fk_rails_c2ac49cbeb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.arena_matches
    ADD CONSTRAINT fk_rails_c2ac49cbeb FOREIGN KEY (zone_id) REFERENCES public.zones(id);


--
-- Name: world_action_offers fk_rails_c30eabb973; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.world_action_offers
    ADD CONSTRAINT fk_rails_c30eabb973 FOREIGN KEY (character_id) REFERENCES public.characters(id);


--
-- Name: character_positions fk_rails_c78a644fee; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.character_positions
    ADD CONSTRAINT fk_rails_c78a644fee FOREIGN KEY (zone_id) REFERENCES public.zones(id);


--
-- Name: arena_applications fk_rails_c886774b40; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.arena_applications
    ADD CONSTRAINT fk_rails_c886774b40 FOREIGN KEY (arena_match_id) REFERENCES public.arena_matches(id);


--
-- Name: city_hotspots fk_rails_cb20d97dd4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.city_hotspots
    ADD CONSTRAINT fk_rails_cb20d97dd4 FOREIGN KEY (destination_zone_id) REFERENCES public.zones(id);


--
-- Name: arena_participations fk_rails_d403ab50fa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.arena_participations
    ADD CONSTRAINT fk_rails_d403ab50fa FOREIGN KEY (npc_template_id) REFERENCES public.npc_templates(id);


--
-- Name: arena_matches fk_rails_db66a2ea91; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.arena_matches
    ADD CONSTRAINT fk_rails_db66a2ea91 FOREIGN KEY (arena_room_id) REFERENCES public.arena_rooms(id);


--
-- Name: currency_transactions fk_rails_e19b71e677; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.currency_transactions
    ADD CONSTRAINT fk_rails_e19b71e677 FOREIGN KEY (shop_account_id) REFERENCES public.shop_accounts(id);


--
-- Name: tile_npcs fk_rails_e9f34b64fd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tile_npcs
    ADD CONSTRAINT fk_rails_e9f34b64fd FOREIGN KEY (npc_template_id) REFERENCES public.npc_templates(id);


--
-- Name: users_roles fk_rails_eb7b4658f8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users_roles
    ADD CONSTRAINT fk_rails_eb7b4658f8 FOREIGN KEY (role_id) REFERENCES public.roles(id);


--
-- Name: airship_journeys fk_rails_ef1bb7103b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.airship_journeys
    ADD CONSTRAINT fk_rails_ef1bb7103b FOREIGN KEY (character_id) REFERENCES public.characters(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20260912090000'),
('20260910170000'),
('20260909160000'),
('20260909120000'),
('20260908110000'),
('20260823220000'),
('20260823180000'),
('20260729120000'),
('20260721090000'),
('20260720090000'),
('20260509211000'),
('20251218132823'),
('20251216091841'),
('20251128075552'),
('20251127100000'),
('20251125152000'),
('20251125103737'),
('20251125103725'),
('20251124130000'),
('20251122123000'),
('20251122120000'),
('20251121150000'),
('20251121142307'),
('20251121135259'),
('20251121135236'),
('20251121090100'),
('20251121090004'),
('20251121090003'),
('20251121090002'),
('20251121084129'),
('20251121084124');
