package com.cohenadair.anglerslog.model;

import android.content.ContentValues;
import android.support.annotation.NonNull;
import android.util.Log;

import com.android.volley.Request;
import com.android.volley.Response;
import com.android.volley.VolleyError;
import com.android.volley.toolbox.JsonObjectRequest;
import com.google.android.gms.maps.model.LatLng;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.UUID;

import static com.cohenadair.anglerslog.database.LogbookSchema.WeatherTable;

/**
 * The Weather class stores weather information. It has the ability to update based on given
 * coordinates. This class uses the <a href="http://openweathermap.org/">Open Weather Map API</a>,
 * and is done in a background thread.
 *
 * Created by Cohen Adair on 2016-01-13.
 */
public class Weather {

    private static final String TAG = "Weather";
    private static final String API_KEY = "35f69a23678dead2c75e0599eadbb4e1";
    private static final String API_URL = "http://api.openweathermap.org/data/2.5/weather?units=imperial";

    private LatLng mCoordinates;

    private int mTemperature;
    private int mWindSpeed;
    private String mSkyConditions;

    public interface OnFetchInterface {
        void onSuccess();
        void onError();
    }

    public Weather(LatLng coordinates) {
        mCoordinates = coordinates;
    }

    public Weather(int temperature, int windSpeed, String skyConditions) {
        mTemperature = temperature;
        mWindSpeed = windSpeed;
        mSkyConditions = skyConditions;
    }

    //region Getters & Setters
    public int getTemperature() {
        return mTemperature;
    }

    public int getWindSpeed() {
        return mWindSpeed;
    }

    public String getSkyConditions() {
        return mSkyConditions;
    }
    //endregion

    public String getTemperatureAsString() {
        return Integer.toString(mTemperature);
    }

    public String getWindSpeedAsString() {
        return Integer.toString(mWindSpeed);
    }

    public JsonObjectRequest getRequest(@NonNull final OnFetchInterface onFetch) {
        if (mCoordinates == null) {
            Log.e(TAG, "Coordinates must not equal null to fetch weather data.");
            return null;
        }

        return new JsonObjectRequest(Request.Method.GET, getUrl(), null, new Response.Listener<JSONObject>() {
            @Override
            public void onResponse(JSONObject jsonObject) {
                parseJson(jsonObject);
                onFetch.onSuccess();
            }
        }, new Response.ErrorListener() {
            @Override
            public void onErrorResponse(VolleyError volleyError) {
                Log.e(TAG, "Volly Error: " + volleyError.toString());
                onFetch.onError();
            }
        });
    }

    private String getUrl() {
        return String.format(API_URL + "&lat=%f&lon=%f&APPID=%s", mCoordinates.latitude, mCoordinates.longitude, API_KEY);
    }

    private void parseJson(JSONObject json) {
        try {
            JSONArray weather = json.getJSONArray("weather");
            if (weather.length() > 0) {
                JSONObject obj = weather.getJSONObject(0);
                mSkyConditions = obj.getString("main");
            }

            JSONObject wind = json.getJSONObject("wind");
            mWindSpeed = (int)Math.round(wind.getDouble("speed"));

            JSONObject temp = json.getJSONObject("main");
            mTemperature = (int)Math.round(temp.getDouble("temp"));
        } catch (JSONException e) {
            e.printStackTrace();
        }
    }

    public ContentValues getContentValues(UUID catchId) {
        ContentValues values = new ContentValues();

        values.put(WeatherTable.Columns.CATCH_ID, catchId.toString());
        values.put(WeatherTable.Columns.TEMPERATURE, mTemperature);
        values.put(WeatherTable.Columns.WIND_SPEED, mWindSpeed);
        values.put(WeatherTable.Columns.SKY_CONDITIONS, mSkyConditions);

        return values;
    }
}
