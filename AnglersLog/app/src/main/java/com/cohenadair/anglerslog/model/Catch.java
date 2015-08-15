package com.cohenadair.anglerslog.model;

import com.cohenadair.anglerslog.model.user_defines.Species;

import java.util.Date;

/**
 * The Catch class stores relative information for a single fishing catch.
 * @author Cohen Adair
 */
public class Catch {

    private Date date;
    private Species fishSpecies;

    public Catch(Date date) {
        this.date = date;
    }

    //region Getters & Setters
    public Date getDate() {
        return date;
    }

    public void setDate(Date date) {
        this.date = date;
    }

    public Species getFishSpecies() {
        return fishSpecies;
    }

    public void setFishSpecies(Species fishSpecies) {
        this.fishSpecies = fishSpecies;
    }
    //endregion
}
