package com.cohenadair.anglerslog.database.cursors;

import android.database.Cursor;
import android.database.CursorWrapper;

import com.cohenadair.anglerslog.model.user_defines.UserDefineObject;

import java.util.UUID;

import static com.cohenadair.anglerslog.database.LogbookSchema.SpeciesTable;

/**
 * A {@link Cursor} wrapper for the {@link com.cohenadair.anglerslog.model.user_defines.Species}
 * object.
 *
 * Created by Cohen Adair on 2015-10-24.
 */
public class UserDefineCursor extends CursorWrapper {

    public UserDefineCursor(Cursor cursor) {
        super(cursor);
    }

    public UserDefineObject getObject() {
        String id = getString(getColumnIndex(SpeciesTable.Columns.ID));
        String name = getString(getColumnIndex(SpeciesTable.Columns.NAME));

        UserDefineObject obj = new UserDefineObject(name);
        obj.setId(UUID.fromString(id));

        return obj;
    }

}