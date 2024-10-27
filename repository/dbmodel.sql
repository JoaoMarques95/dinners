-- Users Table: Stores basic information about users
CREATE TABLE Users (
    user_id UUID PRIMARY KEY,
   email VARCHAR(255) NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,   -- Hashed password for secure login
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    role VARCHAR(50) DEFAULT 'user'  -- Admin flag to identify if user has admin privileges
);

-- User Sessions Table: Manages active sessions and tokens for users
CREATE TABLE User_Sessions (
    session_id UUID PRIMARY KEY,           
    user_id UUID REFERENCES Users(user_id),
    jwt_token TEXT NOT NULL,               
    refresh_token TEXT NOT NULL,           
    issued_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, 
    expires_at TIMESTAMP                   
);

-- Ingredients Table: Stores details of all created ingredients
CREATE TABLE Base_Ingredients (
    base_ingredient_id UUID PRIMARY KEY,             
    name VARCHAR(100) NOT NULL,                 
    category VARCHAR(50),                -- Category, e.g., dairy, vegetables, etc.
    is_global BOOLEAN DEFAULT FALSE,     -- Flag if the ingredient is admin-created
    default_spoilage_flag  BOOLEAN DEFAULT FALSE,       -- Spoilage warning flag
    created_by_user UUID REFERENCES Users(user_id),     -- Identifies the creator if user-defined (can be only customized by that user)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP 
);

-- User Ingredients Table: Links ingredients to users and their stock
CREATE TABLE User_Ingredients (
    user_ingredient_id UUID PRIMARY KEY,            -- Unique identifier for user-ingredient relation
    user_id UUID REFERENCES Users(user_id),         -- Refers to the user who owns the ingredient stock
    base_ingredient_id UUID REFERENCES Base_Ingredients(base_ingredient_id), -- Ingredient in the user's stock
    total_quantity DECIMAL(10, 2),                  -- Total quantity in stock
    portion_quantity DECIMAL(10, 2),                -- Quantity per portion
    is_opened BOOLEAN DEFAULT FALSE,                -- Status if the ingredient is opened
    opened_at TIMESTAMP,                           -- NEW: Track when ingredient was opened
    spoilage_flagged BOOLEAN DEFAULT FALSE,        -- User-specific spoilage flag
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP  -- Last stock update time
);

-- Recipes Table
-- Stores basic details for recipes, including user-specific information when applicable.

CREATE TABLE Base_Recipes (
    base_recipe_id UUID PRIMARY KEY,                       -- Unique identifier for each recipe
    name VARCHAR(255) NOT NULL,                       -- Name of the recipe
    is_global BOOLEAN DEFAULT FALSE,           -- Indicates if the recipe is created by admin
    created_by_user UUID REFERENCES Users(user_id),           -- User who created the recipe (if non-admin)
    preparation_time INTEGER,                         -- Time to prepare the recipe
    preparation_time_unit VARCHAR(255),  
    default_servings INTEGER NOT NULL,             -- NEW: Added default servings
    steps TEXT,                                       -- Instructions or steps to complete the recipe
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP    -- Timestamp when the recipe was created
);

-- Recipe Ingredients Table: Links recipes with their required ingredients
CREATE TABLE Recipe_Ingredients (
    recipe_ingredient_id UUID PRIMARY KEY,        -- Unique identifier for recipe-ingredient relation
    base_recipe_id UUID REFERENCES Base_Recipes(base_recipe_id), -- Recipe that requires this ingredient
    base_ingredient_id UUID REFERENCES Base_Ingredients(base_ingredient_id), -- Required ingredient
    quantity FLOAT,                                -- Quantity needed in the recipe
    unit VARCHAR(255)                                 -- UOM needed
);


-- User Recipe Details: Stores user-specific details related to recipes
CREATE TABLE User_Recipes (
    user_recipe_id UUID PRIMARY KEY,       -- Unique identifier for user-recipe relation
    user_id UUID REFERENCES Users(user_id),       -- User associated with these details
    base_recipe_id UUID REFERENCES Base_Recipes(base_recipe_id), -- Recipe associated with these details
    notes TEXT,                                   -- User's notes for this recipe
    photo_url VARCHAR(255),                        -- URL for any photo the user attaches
    rating INT,                                   -- User's notes for this recipe
);



-- Meal Plans Table: Manages scheduled meal plans for users
CREATE TABLE Meal_Plans (
    meal_plan_id UUID PRIMARY KEY,                  -- Unique identifier for each meal plan
    user_id UUID REFERENCES Users(user_id),         -- User associated with the meal plan
    base_recipe_id UUID REFERENCES Base_Recipes(base_recipe_id),   -- Recipe planned for the meal
    scheduled_for DATE,                             -- Date for the scheduled meal
    meal_type TEXT,                                 -- Type of meal (e.g., breakfast, lunch, dinner)
    servings INTEGER,                               -- Number of servings planned for the meal
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Creation time of the meal plan
    completed_at TIMESTAMP, -- completed_at time of the meal plan
    notes TEXT                                      -- Optional notes about the meal
);

-- Shopping List Table: Manages user's shopping list items
CREATE TABLE Shopping_List (
    shopping_list_id UUID PRIMARY KEY,          -- Unique identifier for each shopping list item
    user_id UUID REFERENCES Users(user_id),     -- User who owns this shopping list
    base_ingredient_id UUID REFERENCES Base_Ingredients(base_ingredient_id), -- Ingredient to buy
    quantity DECIMAL(10, 2),                    -- Quantity needed for shopping
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Time when item was added to the list
    purchased BOOLEAN DEFAULT FALSE             -- Purchase status of the item
);

-- Notifications Table: Stores notifications sent to users
CREATE TABLE Notifications (
    notification_id UUID PRIMARY KEY,           -- Unique identifier for each notification
    user_id UUID REFERENCES Users(user_id),     -- User associated with the notification
    message TEXT NOT NULL,                      -- Message content
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Time the notification was sent
    read_at TIMESTAMP                           -- Time the notification was read
);


-- All core constraints in one place
-- Unique constraints
ALTER TABLE Base_Ingredients ADD CONSTRAINT unique_ingredient_name 
    UNIQUE (name, created_by_user);

ALTER TABLE Base_Recipes ADD CONSTRAINT unique_recipe_name 
    UNIQUE (name, created_by_user);

-- Quantity constraintss
ALTER TABLE User_Ingredients 
    ADD CONSTRAINT positive_quantities 
    CHECK (total_quantity >= 0 AND portion_quantity >= 0);

ALTER TABLE User_Recipe 
    ADD CONSTRAINT valid_rating 
    CHECK (rating >= 1 AND rating <= 5);

-- Servings constraints
ALTER TABLE Base_Recipes
    ADD CONSTRAINT positive_default_servings 
    CHECK (default_servings > 0);

ALTER TABLE Meal_Plans 
    ADD CONSTRAINT positive_servings 
    CHECK (servings > 0);

-- Possible roles for user
ALTER TABLE Users 
    ADD CONSTRAINT valid_role 
    CHECK (role IN ('user', 'admin'));



