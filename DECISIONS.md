# Decisions Log

> Keep this concise but informative. One entry per pivotal choice or method change.

## 2026-03-16 – Template initialized
- Context: Starting analysis on <topic>.
- Initial plan: <brief description>.
- Notes: DECISIONS.md will capture key steps and rationale as work progresses.

---

## Template Entry (copy-paste and fill)

## 2026-03-16 – Data sources explored
- Context: Digging deeper into the data.
- Initial plan: Get working with some of the data; explore what we can do.
- Notes: 
    Data sources:
    - Port data:
        - There is weekly import data at ports and from states in 2023 and 2024
                - see tabs in FY23 Mexican Cattle Origin State to Port of Entry Count.xlsx in the main folder, and FY24
                - its a bit of a mess and would require someone to piece it together

        - There is total imports by port, state, and type of cow for 2023 and 2024 (not weekly)
            - see raw data, 'cattle port state and bovine type 2023 and 2024.xlsx';
                    this data was taken out of the fy23 and FY24 mexican cattle origin state to port... data files
            - There is also total volume by port for 2022, 2023, and 2024, though it is probably redundant for 2023 and 2024 since we have the more detailed data by state and type of cow
                - see raw data, 'cattle port data.xlsx' volume tab

        - There is type of rejection data by port and state for 2022 to 2024; it is tied to total volume data as well

    - Mexico inventory data:
        - Bovines by state and village area for Mexico exists for 2022
            - this could be use to create a spatial map of the cow inventory in Mexico
            - Mexico also has its own census data; not sure where it is or if this came from it.

    - Mexico cases:
        - There is data on cases in Mexico; see NWS 
            - data is rganized by date, state, municipality, and has info on origin and destination if the cattle was being moved (most don't have a origin & destination but they all have a state and municipality of the case)
        - Last update was back in september of 2025
        
    - Mexico georeferences:
        - Mexico municipalities and states have georeference data that we can use to map the cases and inventory data; this is in the raw data folder as well
            - https://figshare.com/articles/dataset/_b_Mexico_GeoJSON_States_and_Municipalities_2024_b_/31236322

### <YYYY-MM-DD> – <Decision/Outcome Title>
**Question/Goal:**
- What were we trying to decide or test?

Where is NWS in Mexico?
- Use NWS cases data to see where it is
    - Can extend this by using destination data to assume NWS successfully moved there
        - Projecting cases across Mexico using spatio-temporal modeling and/or graph neural networks might be more in-depth than this analysis has the time for.

Volume arriving and rate of rejections arriving at each port
    Multivariate analsis of type of rejections by port
- Use port data to calculate this; we have total volume and rejections by port and state

Volume of cattle by state arriving at each port
    - attribute problems across their inventory by the rejection makeup of those cattle's origins at each port
- use port data with state and type of cow at each port; rejection data will have be appropriated to the state; we have rejection data by port but not state, so we will have to make some assumptions about how to attribute the rejections to the different states

Inventory of problematic cattle in mexico
    The purpose here is because they are only going to open a few ports for now, so we want to know where the cows are in Mexico and how that relates to the rejections at the ports; this will give us some understanding of problems based on what is arriving at ports
- Use inventory data to see where the cows are in Mexico; attribute problems across their inventory by the rejection makeup of those cattle's origins at each port


**What we tried:**
- Methods or analyses attempted (link to files in `notebooks/exploration/` or `src/sandbox/`)

**Result/Comparison:**
- Key metrics or qualitative findings

**Decision & Rationale:**
- What did we choose and why (policy, interpretability, stability, performance, data quality, etc.)

**Implications:**
- Changes to pipeline, reporting, or future work

**References:**
- Link to PR/commit/branch, literature, or prior analysis (optional)
