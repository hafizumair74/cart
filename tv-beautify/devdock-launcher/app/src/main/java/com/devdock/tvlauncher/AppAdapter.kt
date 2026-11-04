package com.devdock.tvlauncher

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageView
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView

class AppAdapter(
    private var items: List<AppEntry>,
    private val onLaunch: (AppEntry) -> Unit,
) : RecyclerView.Adapter<AppAdapter.Holder>() {

    fun submit(list: List<AppEntry>) {
        items = list
        notifyDataSetChanged()
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): Holder {
        val v = LayoutInflater.from(parent.context).inflate(R.layout.item_app, parent, false)
        return Holder(v)
    }

    override fun onBindViewHolder(holder: Holder, position: Int) {
        val item = items[position]
        holder.icon.setImageDrawable(item.icon)
        holder.label.text = item.label
        holder.itemView.setOnClickListener { onLaunch(item) }
    }

    override fun getItemCount() = items.size

    class Holder(v: View) : RecyclerView.ViewHolder(v) {
        val icon: ImageView = v.findViewById(R.id.icon)
        val label: TextView = v.findViewById(R.id.label)
    }
}
