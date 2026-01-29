// supabase/functions/push_notification/index.ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
const ONESIGNAL_APP_ID = Deno.env.get('ONESIGNAL_APP_ID')!
const ONESIGNAL_REST_API_KEY = Deno.env.get('ONESIGNAL_REST_API_KEY')!
serve(async (req) => {
  try {
    const { record } = await req.json()

    // Validate that we have a user_id to target
    if (!record.user_id) {
      return new Response('No user_id in record', { status: 400 })
    }
    // Construct OneSignal payload
    const payload = {
      app_id: ONESIGNAL_APP_ID,
      include_external_user_ids: [record.user_id], // Target specific user
      headings: { en: record.title },
      contents: { en: record.body },
      data: {
        type: record.type,
        related_id: record.related_id,
        notification_id: record.id
      }, // Metadata for the app to use on tap
    }
    // Send to OneSignal
    const response = await fetch('https://onesignal.com/api/v1/notifications', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'Authorization': `Basic ${ONESIGNAL_REST_API_KEY}`,
      },
      body: JSON.stringify(payload),
    })
    const result = await response.json()
    console.log('OneSignal Result:', result)
    return new Response(JSON.stringify(result), {
      headers: { 'Content-Type': 'application/json' },
      status: response.status
    })
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { 'Content-Type': 'application/json' },
      status: 500
    })
  }
})