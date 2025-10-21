# International Debt Data Flow Diagram

```mermaid
graph TD
    %% 1. Data Sources (External Entity)
    A[Source Data long_term-debt, short_term_debt, total_external_debt] -- Extract --> B{3 x Staging Tables};

    %% 2. Processes (Preparation & Cleaning)
    B -- Transform (UPPER/TRIM) --> C[Clean & Standardize Data];

    %% 3. Data Stores (Intermediate Tables)
    C --> D(short_term_debt_clean);
    C --> E(long_term_debt_clean);
    C --> F(total_external_debt_clean);

    %% 4. Main Transformation Process (View Creation)
    subgraph Data Processing & Consolidation
    D & E & F --> G{Join & Calculate Metrics};
    end

    %% 5. Output/Final Data Store (View)
    G -- Load --> H(debt_summary VIEW);

    %% 6. Final Outputs (External Entity/Analysis)
    H -- Query & Report --> I[Analysis & Reporting High Dependency Identification: Identifying countries based on risk metrics, such as those where short-term debt exceeds a high threshold e.g., the query WHERE short_pct > 60.];
