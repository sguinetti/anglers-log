package com.cohenadair.anglerslog.model;

import java.util.Comparator;

/**
 * Stores anything used by the application's stats features.
 * Created by Cohen Adair on 2016-01-26.
 */
public class Stats {

    public static class Quantity {
        private String mName;
        private int mQuantity;

        public Quantity(String name, int quantity) {
            mName = name;
            mQuantity = quantity;
        }

        public String getName() {
            return mName;
        }

        public int getQuantity() {
            return mQuantity;
        }
    }

    public static class QuantityComparator implements Comparator<Quantity> {
        @Override
        public int compare(Quantity lhs, Quantity rhs) {
            if (lhs.getQuantity() < rhs.getQuantity())
                return -1;
            else if (lhs.getQuantity() == rhs.getQuantity())
                return 0;
            else
                return 1;
        }
    }

}
